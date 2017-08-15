defmodule AlertProcessor.Model.User do
  @moduledoc """
  User struct and functions
  """
  @type t :: %__MODULE__{
    id: String.t,
    email: String.t,
    phone_number: String.t,
    role: String.t,
    vacation_start: DateTime.t,
    vacation_end: DateTime.t,
    do_not_disturb_start: Time.t,
    do_not_disturb_end: Time.t,
    amber_alert_opt_in: boolean()
  }

  @type id :: String.t

  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias AlertProcessor.{Aws.AwsClient, Model.Subscription, HoldingQueue, Repo}
  alias Comeonin.Bcrypt
  alias Ecto.Multi

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    has_one :subscription, Subscription
    field :email, :string, null: false
    field :phone_number, :string
    field :role, :string
    field :vacation_start, :utc_datetime
    field :vacation_end, :utc_datetime
    field :do_not_disturb_start, :time
    field :do_not_disturb_end, :time
    field :encrypted_password, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :sms_toggle, :boolean, virtual: true
    field :amber_alert_opt_in, :boolean, default: true

    timestamps()
  end

  @permitted_fields ~w(email phone_number role vacation_start
    vacation_end do_not_disturb_start do_not_disturb_end password
    password_confirmation amber_alert_opt_in)a
  @required_fields ~w(email password)a

  @active_admin_roles ~w(customer_support application_administration)
  @admin_roles ["deactivated_admin" | @active_admin_roles]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
  end

  def create_account(params) do
    %__MODULE__{}
    |> create_account_changeset(params)
    |> PaperTrail.insert()
    |> normalize_papertrail_result()
  end

  def create_admin_account(params) do
    %__MODULE__{}
    |> cast(params, [:role])
    |> validate_required([:role])
    |> validate_inclusion(:role, @admin_roles)
    |> create_account_changeset(params)
    |> PaperTrail.insert()
    |> normalize_papertrail_result()
  end

  @doc """
  Builds changeset used for registering a new user account
  """
  def create_account_changeset(struct, params \\ %{}) do
    params =
      case params do
        %{"sms_toggle" => "false"} -> Map.put(params, "phone_number", nil)
        _ -> params
      end
    struct
    |> changeset(params)
    |> change(%{do_not_disturb_start: ~T[22:00:00], do_not_disturb_end: ~T[07:00:00]})
    |> validate_format(:email, ~r/@/, message: "Please enter a valid email address.")
    |> unique_constraint(:email, message: "Sorry, that email has already been taken.")
    |> validate_confirmation(:password, required: true, message: "Password and password confirmation did not match.")
    |> validate_length(:password, min: 6, message: "Password must be at least six characters long.")
    |> validate_format(:password, ~r/[^a-zA-Z\s:]{1}/, message: "Password must contain one number or special character (? & % $ # !, etc).")
    |> validate_format(:phone_number, ~r/^[0-9]{10}$/, message: "Phone number is not in a valid format.")
    |> hash_password()
  end

  def update_account(struct, params) do
    struct
    |> update_account_changeset(params)
    |> PaperTrail.update()
    |> normalize_papertrail_result()
  end

  @doc """
  Builds changeset for updating an existing user account
  """
  def update_account_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, ~w(phone_number do_not_disturb_start do_not_disturb_end amber_alert_opt_in))
    |> validate_format(:phone_number, ~r/^[0-9]{10}$/, message: "Phone number is not in a valid format.")
  end

  def disable_account(struct) do
    struct
    |> disable_account_changeset()
    |> PaperTrail.update()
    |> normalize_papertrail_result()
  end

  def disable_account_changeset(struct) do
    struct
    |> change(encrypted_password: "")
    |> change(vacation_start: DateTime.utc_now())
    |> change(vacation_end: DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC"))
  end

  def deactivate_admin(struct) do
    struct
    |> deactivate_admin_changeset()
    |> PaperTrail.update()
    |> normalize_papertrail_result()
  end

  def deactivate_admin_changeset(struct) do
    change(struct, role: "deactivated_admin")
  end

  def activate_admin(struct, params) do
    struct
    |> activate_admin_changeset(params)
    |> PaperTrail.update()
    |> normalize_papertrail_result()
  end

  def activate_admin_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:role])
    |> validate_required([:role])
    |> validate_inclusion(:role, @active_admin_roles)
  end

  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        changeset
        |> put_change(:encrypted_password, Bcrypt.hashpwsalt(password))
        |> delete_change(:password)
        |> delete_change(:password_confirmation)
      _ ->
        changeset
    end
  end

  @doc """
  Builds a changeset to verify login
  """
  def login_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :password])
    |> validate_required([:email, :password])
  end

  def update_password(user, params) do
    user
    |> update_password_changeset(params)
    |> PaperTrail.update()
    |> normalize_papertrail_result()
  end

  @doc """
  Builds a changeset to update password
  """
  def update_password_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:password, :password_confirmation])
    |> validate_required(:password)
    |> validate_confirmation(:password, required: true, message: "Password and password confirmation did not match.")
    |> validate_length(:password, min: 6, message: "Password must be at least six characters long.")
    |> validate_format(:password, ~r/[^a-zA-Z\s:]{1}/, message: "Password must contain one number or special character (? & % $ # !, etc).")
    |> hash_password()
  end

  def update_vacation(user, params) do
    user
    |> update_vacation_changeset(params)
    |> PaperTrail.update()
    |> normalize_papertrail_result()
  end

  def remove_vacation(user) do
    user
    |> remove_vacation_changeset()
    |> PaperTrail.update()
    |> normalize_papertrail_result()
  end

  @spec update_vacation_changeset(__MODULE__.t, map) :: Ecto.Changeset.t
  def update_vacation_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, ~w(vacation_start vacation_end)a)
    |> validate_vacation_period()
  end

  defp validate_vacation_period(changeset) do
    vacation_start = get_field(changeset, :vacation_start)
    vacation_end = get_field(changeset, :vacation_end)
    case {vacation_start, vacation_end} do
      {nil, nil} ->
        changeset
      {vacation_start, vacation_end} ->
        now = DateTime.utc_now()
        with {:lt, :valid_period} <- {DateTime.compare(vacation_start, vacation_end), :valid_period},
            {:lt, :in_future} <- {DateTime.compare(now, vacation_end), :in_future} do
          changeset
        else
          {_, :in_future} ->
            add_error(changeset, :vacation_end, "Vacation period must end sometime in the future.")
          {_, :valid_period} ->
            add_error(changeset, :vacation_end, "Vacation period must have an end time later than the start time.")
        end
    end
  end

  @spec remove_vacation_changeset(__MODULE__.t) :: Ecto.Changeset.t
  def remove_vacation_changeset(struct) do
    struct
    |> change(vacation_start: nil)
    |> change(vacation_end: nil)
  end

  def opt_in_phone_number(%__MODULE__{phone_number: nil}), do: {:ok, nil}
  def opt_in_phone_number(%__MODULE__{phone_number: phone_number}) do
    phone_number
    |> ExAws.SNS.opt_in_phone_number()
    |> AwsClient.request()
  end

  @doc """
  Checks if user's login credentials are valid
  """
  def authenticate(%{"email" => email, "password" => password} = params) do
    user = Repo.get_by(__MODULE__, email: email)

    cond do
      user && user.encrypted_password == "" ->
        {:error, :disabled}
      check_password(user, password) ->
        {:ok, user}
      true ->
        {:error, login_changeset(%__MODULE__{}, params)}
    end
  end

  def check_password(user, password) do
    case user do
      nil -> Bcrypt.dummy_checkpw()
      _ -> Bcrypt.checkpw(password, user.encrypted_password)
    end
  end

  @doc """
  Checks if a user's login credentials are valid and that the user has either the
  customer_support or application_administration role
  """
  def authenticate_admin(params) do
    params
    |> authenticate()
    |> authorize_admin()
  end

  defp authorize_admin({:ok, %__MODULE__{role: role}} = {_, user}) when role in @active_admin_roles do
     {:ok, user}
  end

  defp authorize_admin({:ok, %__MODULE__{role: "deactivated_admin"}}), do: :deactivated
  defp authorize_admin({:ok, _user}), do: :unauthorized
  defp authorize_admin({:error, result}), do: {:error, result}

  @doc """
  Returns user ids based on a list of phone numbers
  """
  def ids_by_phone_numbers(phone_numbers) do
    Repo.all(from u in __MODULE__, where: u.phone_number in ^phone_numbers, select: u.id)
  end

  @doc """
  Takes a list of user ids and puts on vacation mode ending in the year 9999
  """
  def put_users_on_indefinite_vacation(user_ids) do
    user_ids
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn({user_id, index}, acc) ->
          Multi.run(acc, {:user, index}, fn _ ->
            __MODULE__
            |> Repo.get(user_id)
            |> update_vacation_changeset(%{vacation_start: DateTime.utc_now(), vacation_end: DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC")})
            |> PaperTrail.update()
          end)
        end)
    |> Repo.transaction()
    |> normalize_papertrail_result()
  end

  @doc """
  take a user and put into vacation mode ending in the year 9999
  """
  @spec put_user_on_indefinite_vacation(__MODULE__.t) :: {:ok, __MODULE__.t} | {:error, Ecto.Changeset.t}
  def put_user_on_indefinite_vacation(user) do
    user
    |> update_vacation_changeset(%{vacation_start: DateTime.utc_now(), vacation_end: DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC")})
    |> PaperTrail.update()
    |> normalize_papertrail_result()
  end

  @spec clear_holding_queue_for_user_id(id) :: :ok
  def clear_holding_queue_for_user_id(user_id) do
    HoldingQueue.remove_user_notifications(user_id)
  end

  defp normalize_papertrail_result({:ok, %{model: user}}), do: {:ok, user}
  defp normalize_papertrail_result(result), do: result

  def for_email(email) do
    Repo.get_by(__MODULE__, email: email)
  end

  @doc """
  Returns all users with one of the admin_roles
  """
  def all_admin_users do
    Repo.all(from u in __MODULE__, where: u.role in @admin_roles)
  end

  def admin_one!(id) do
    Repo.one!(from u in __MODULE__,
    where: u.role in @admin_roles and u.id == ^id)
  end

  @doc """
  return list of users ordered by email address
  """
  def ordered_by_email(page \\ 1) do
    __MODULE__
    |> order_by(:email)
    |> Repo.paginate(page: page, page_size: 25)
  end

  @doc """
  filter users based on search criteria for either email
  address or phone number
  """
  def search_by_contact_info(search_term, page \\ 1) do
    __MODULE__
    |> where([u], ilike(u.email, ^"%#{search_term}%"))
    |> or_where([u], ilike(u.phone_number, ^"%#{search_term}%"))
    |> order_by(:email)
    |> Repo.paginate(page: page, page_size: 25)
  end

  def is_admin?(nil), do: false
  def is_admin?(user), do: user.role in @active_admin_roles

  @doc """
  return one user based on id
  """
  def find_by_id(user_id) do
    Repo.get(__MODULE__, user_id)
  end

  @doc """
  log action by admin user using papertrail.
  """
  def log_admin_action(:view_subscriber, admin_user, user) do
    admin_user
    |> Ecto.Changeset.change()
    |> PaperTrail.update(originator: admin_user, origin: "admin:view-subscriber", meta: %{subscriber_id: user.id, subscriber_email: user.email})
    |> normalize_papertrail_result()
  end
end
