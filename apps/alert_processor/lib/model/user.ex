defmodule AlertProcessor.Model.User do
  @moduledoc """
  User struct and functions
  """
  @type id :: String.t()
  @type t :: %__MODULE__{
          id: id,
          email: String.t(),
          phone_number: String.t(),
          role: String.t(),
          digest_opt_in: boolean,
          sms_opted_out_at: DateTime.t(),
          communication_mode: String.t(),
          email_rejection_status: String.t()
        }

  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias AlertProcessor.{Aws.AwsClient, Model.Subscription, Model.Trip, Repo}
  alias Comeonin.Bcrypt
  alias Ecto.Multi

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    has_one(:subscription, Subscription)
    has_many(:trips, Trip)
    field(:email, :string, null: false)
    field(:phone_number, :string)
    field(:role, :string)
    field(:encrypted_password, :string)
    field(:digest_opt_in, :boolean, default: true)
    field(:email_rejection_status, :string)
    field(:sms_opted_out_at, :utc_datetime)
    field(:communication_mode, :string, null: false, default: "email")
    field(:password, :string, virtual: true)
    field(:sms_toggle, :boolean, virtual: true)

    timestamps()
  end

  @permitted_fields ~w(
    email
    phone_number
    role
    password
    digest_opt_in
    email_rejection_status
    sms_opted_out_at
    communication_mode
  )a
  @required_fields ~w(email password)a

  @communication_modes ~w(none email sms)
  @email_rejection_statuses [nil, "bounce", "complaint"]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, required_fields \\ []) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(required_fields, message: "This field is required.")
    |> validate_inclusion(:communication_mode, @communication_modes)
    |> validate_inclusion(:email_rejection_status, @email_rejection_statuses)
  end

  def create_account(params) do
    case %__MODULE__{}
         |> create_account_changeset(params)
         |> PaperTrail.insert()
         |> normalize_papertrail_result() do
      {:ok, user} ->
        opt_in_phone_number(user)
        {:ok, user}

      result ->
        result
    end
  end

  def update_account(struct, params, originator) do
    changeset = update_account_changeset(struct, params)

    result =
      changeset
      |> PaperTrail.update(
        originator: wrap_id(originator),
        origin: nil,
        meta: %{subscriber_id: struct.id, subscriber_email: struct.email}
      )
      |> normalize_papertrail_result()

    case {result, changeset} do
      {{:ok, updated_user}, %{changes: %{phone_number: _}}} ->
        opt_in_phone_number(updated_user)
        result

      _ ->
        result
    end
  end

  def update_password(user, params, originator) do
    user
    |> update_password_changeset(params)
    |> PaperTrail.update(
      originator: wrap_id(originator),
      origin: nil,
      meta: %{subscriber_id: user.id, subscriber_email: user.email}
    )
    |> normalize_papertrail_result()
  end

  @doc """
  Builds changeset used for registering a new user account
  """
  def create_account_changeset(struct, params \\ %{}) do
    struct
    |> changeset(params, @required_fields)
    |> update_change(:email, &String.trim/1)
    |> update_change(:email, &lowercase_email/1)
    |> validate_email()
    |> validate_password()
    |> clear_phone_if_mode_is_email(params)
    |> update_change(:phone_number, &clean_phone_number/1)
    |> validate_phone_number()
    |> hash_password()
  end

  @doc """
  Builds changeset for updating an existing user account
  """
  def update_account_changeset(
        struct,
        %{"communication_mode" => "sms", "email" => _email} = params
      ) do
    struct
    |> changeset(params, [:phone_number, :email])
    |> update_change(:phone_number, &clean_phone_number/1)
    |> validate_phone_number()
    |> update_change(:email, &String.trim/1)
    |> update_change(:email, &lowercase_email/1)
    |> validate_email()
  end

  def update_account_changeset(struct, %{"communication_mode" => "sms"} = params) do
    struct
    |> changeset(params, [:phone_number])
    |> update_change(:phone_number, &clean_phone_number/1)
    |> validate_phone_number()
  end

  def update_account_changeset(struct, %{"communication_mode" => "email"} = params) do
    struct
    |> changeset(params, [:email])
    |> validate_email()
    |> update_change(:email, &String.trim/1)
    |> update_change(:email, &lowercase_email/1)
    |> update_change(:phone_number, &clear_value/1)
  end

  def update_account_changeset(struct, params), do: changeset(struct, params)

  defp validate_email(changeset) do
    changeset
    |> validate_format(
      :email,
      # The same validation used by the `mail` library
      ~r/[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}/,
      message: "Please enter a valid email address."
    )
    |> unique_constraint(:email, message: "Sorry, that email has already been taken.")
  end

  defp clear_phone_if_mode_is_email(changeset, %{"communication_mode" => "email"}) do
    update_change(changeset, :phone_number, &clear_value/1)
  end

  defp clear_phone_if_mode_is_email(changeset, _), do: changeset

  defp clear_value(_), do: nil

  defp validate_phone_number(changeset) do
    validate_format(
      changeset,
      :phone_number,
      ~r/^[0-9]{10}$/,
      message: "Phone number is not in a valid format."
    )
  end

  defp validate_password(changeset) do
    changeset
    |> validate_length(
      :password,
      min: 8,
      message: "Password must be at least 8 characters long."
    )
    |> validate_format(
      :password,
      ~r/_|\d|\W/u,
      message: "Password must contain at least one number or symbol."
    )
  end

  defp clean_phone_number(nil), do: nil
  defp clean_phone_number(value), do: String.replace(value, ~r/\D/, "")

  defp lowercase_email(nil), do: ""
  defp lowercase_email(value), do: String.downcase(value)

  defp update_password_changeset(struct, params) do
    struct
    |> changeset(params, ~w(password)a)
    |> validate_password()
    |> hash_password()
  end

  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        changeset
        |> put_change(:encrypted_password, Bcrypt.hashpwsalt(password))
        |> delete_change(:password)

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
    changeset = login_changeset(%__MODULE__{}, params)

    case changeset.errors do
      [] ->
        user = Repo.get_by(__MODULE__, email: String.downcase(email))

        cond do
          user && user.encrypted_password == "" ->
            {:error, :disabled}

          check_password(user, password) ->
            {:ok, user}

          true ->
            {:error, changeset}
        end

      _ ->
        {:error, changeset}
    end
  end

  def check_password(user, password) do
    case user do
      nil -> Bcrypt.dummy_checkpw()
      _ -> Bcrypt.checkpw(password, user.encrypted_password)
    end
  end

  @doc "Records an email rejection status for a user and disables notifications for them."
  def set_email_rejection(user, status) when not is_nil(status),
    do: update_email_rejection(user, "none", status, "email-rejection")

  @doc "Unsets a user's email rejection status and re-enables email notifications for them."
  def unset_email_rejection(user),
    do: update_email_rejection(user, "email", nil, "email-unrejection")

  defp update_email_rejection(user, mode, status, origin) do
    user
    |> update_account_changeset(%{communication_mode: mode, email_rejection_status: status})
    |> PaperTrail.update(origin: origin)
    |> normalize_papertrail_result()
  end

  @doc """
  Given a list of phone numbers, sets the corresponding users as opted out of SMS notifications.
  This deletes the users' phone numbers, so subsequent calls with the same list of phone numbers
  will not result in additional updates.
  """
  @spec set_sms_opted_out([String.t()]) ::
          {:ok, %{Multi.name() => t()}} | {:error, Multi.name(), t(), %{Multi.name() => t()}}
  def set_sms_opted_out(phone_numbers) do
    from(u in __MODULE__, where: u.phone_number in ^phone_numbers)
    |> Repo.all()
    |> Enum.reduce(Multi.new(), fn %{id: user_id} = user, multi ->
      Multi.run(multi, user_id, fn _ ->
        user
        |> update_account_changeset(%{
          phone_number: nil,
          communication_mode: "none",
          sms_opted_out_at: DateTime.utc_now()
        })
        |> PaperTrail.update(origin: "sms-opt-out")
        |> normalize_papertrail_result()
      end)
    end)
    |> Repo.transaction()
  end

  defp normalize_papertrail_result({:ok, %{model: user}}), do: {:ok, user}
  defp normalize_papertrail_result(result), do: result

  @spec for_email(String.t()) :: t | nil
  def for_email(email) do
    Repo.get_by(__MODULE__, email: String.downcase(email))
  end

  @spec wrap_id(__MODULE__.t() | String.t()) :: __MODULE__.t()
  def wrap_id(%__MODULE__{} = user), do: user
  def wrap_id(user_id), do: %__MODULE__{id: user_id}

  @spec admin?(t()) :: boolean
  def admin?(%__MODULE__{role: "admin"}), do: true
  def admin?(_user), do: false

  @spec make_admin(t()) :: tuple
  def make_admin(user) do
    update_account(user, %{"role" => "admin"}, user.id)
  end

  @spec make_not_admin(t()) :: tuple
  def make_not_admin(user) do
    update_account(user, %{"role" => "user"}, user.id)
  end

  def inside_opt_out_freeze_window?(%__MODULE__{sms_opted_out_at: nil}), do: false

  def inside_opt_out_freeze_window?(%__MODULE__{sms_opted_out_at: sms_opted_out_at}),
    do: Date.diff(Date.utc_today(), DateTime.to_date(sms_opted_out_at)) <= 30
end
