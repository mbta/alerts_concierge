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
  alias AlertProcessor.{Model.Subscription, Repo}
  alias Comeonin.Bcrypt

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
    field :encrypted_password, :string, null: false
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

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
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
    |> validate_format(:email, ~r/^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$/, message: "Please enter a valid email address.")
    |> unique_constraint(:email, message: "Sorry, that email has already been taken.")
    |> validate_confirmation(:password, required: true, message: "Password and password confirmation did not match.")
    |> validate_length(:password, min: 6, message: "Password must be at least six characters long.")
    |> validate_format(:password, ~r/[^a-zA-Z\s:]{1}/, message: "Password must contain one number or special character (? & % $ # !, etc).")
    |> validate_format(:phone_number, ~r/^[0-9]{10}$/, message: "Phone number is not in a valid format.")
    |> hash_password()
  end

  @doc """
  Builds changeset for updating an existing user account
  """
  def update_account_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, ~w(phone_number do_not_disturb_start do_not_disturb_end amber_alert_opt_in))
    |> validate_format(:phone_number, ~r/^[0-9]{10}$/, message: "Phone number is not in a valid format.")
  end

  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :encrypted_password, Bcrypt.hashpwsalt(password))
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

  @doc """
  Builds a changeset to update password
  """
  def update_password_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(:password)
    |> validate_confirmation(:password, required: true, message: "Password and password confirmation did not match.")
    |> validate_length(:password, min: 6, message: "Password must be at least six characters long.")
    |> validate_format(:password, ~r/[^a-zA-Z\s:]{1}/, message: "Password must contain one number or special character (? & % $ # !, etc).")
    |> hash_password()
  end

  @spec update_account_changeset(__MODULE__.t, map) :: Ecto.Changeset.t
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

  def remove_vacation_period_changeset(struct) do
    struct
    |> change(vacation_start: nil)
    |> change(vacation_end: nil)
  end

  @doc """
  Checks if user's login credentials are valid
  """
  def authenticate(%{"email" => email, "password" => password} = params) do
    user = Repo.get_by(__MODULE__, email: email)
    if check_password(user, password) do
      {:ok, user}
    else
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
  Returns user ids based on a list of phone numbers
  """
  def ids_by_phone_numbers(phone_numbers) do
    Repo.all(from u in __MODULE__, where: u.phone_number in ^phone_numbers, select: u.id)
  end

  @doc """
  Takes a list of user ids and puts on vacation mode ending in the year 9999
  """
  def put_users_on_indefinite_vacation(user_ids) do
    Repo.update_all(from(u in __MODULE__, where: u.id in ^user_ids),
                    set: [vacation_start: DateTime.utc_now(),
                          vacation_end: DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC")])
  end
end
