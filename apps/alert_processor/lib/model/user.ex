defmodule AlertProcessor.Model.User do
  @moduledoc """
  User struct and functions
  """
  @type id :: String.t()
  @type t :: %__MODULE__{
          id: id,
          email: String.t(),
          phone_number: String.t() | nil,
          role: String.t(),
          digest_opt_in: boolean,
          sms_opted_out_at: DateTime.t(),
          communication_mode: String.t(),
          email_rejection_status: String.t()
        }

  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias AlertProcessor.{Aws.AwsClient, Model.Subscription, Model.Trip, Repo}
  alias Ecto.Multi

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    has_one(:subscription, Subscription)
    has_many(:trips, Trip)
    field(:email, :string)
    field(:phone_number, :string)
    field(:role, :string)
    field(:digest_opt_in, :boolean, default: true)
    field(:email_rejection_status, :string)
    field(:sms_opted_out_at, :utc_datetime)
    field(:communication_mode, :string, default: "email")
    field(:sms_toggle, :boolean, virtual: true)

    timestamps(type: :utc_datetime)
  end

  @permitted_fields ~w(
    email
    phone_number
    role
    digest_opt_in
    email_rejection_status
    sms_opted_out_at
    communication_mode
  )a
  @required_fields ~w(email)a

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

  @doc """
  Builds changeset used for registering a new user account
  """
  def create_account_changeset(struct, params \\ %{}) do
    struct
    |> changeset(params, @required_fields)
    |> clean_email()
    |> validate_email()
    |> update_change(:phone_number, &clean_phone_number/1)
    |> validate_phone_number()
  end

  @doc """
  Builds changeset for updating an existing user account
  """
  def update_account_changeset(
        struct,
        %{"communication_mode" => "sms", "email" => _email} = params
      ) do
    struct
    |> changeset(params, [:email])
    # Validate phone number as required separately for the custom error message.
    |> validate_required([:phone_number],
      message: "Please click the link above to add your phone number to your account."
    )
    |> update_change(:phone_number, &clean_phone_number/1)
    |> validate_phone_number()
    |> validate_accept_tnc(params)
    |> clean_email()
    |> validate_email()
  end

  def update_account_changeset(
        struct,
        %{"communication_mode" => "sms"} = params
      ) do
    struct
    |> changeset(params)
    # Validate phone number as required separately for the custom error message.
    |> validate_required([:phone_number],
      message: "Please click the link above to add your phone number to your account."
    )
    |> update_change(:phone_number, &clean_phone_number/1)
    |> validate_phone_number()
    |> validate_accept_tnc(params)
  end

  def update_account_changeset(struct, %{"communication_mode" => "email"} = params) do
    struct
    |> changeset(params, [:email])
    |> clean_email()
    |> validate_email()
    |> update_change(:phone_number, &clear_value/1)
  end

  def update_account_changeset(struct, params), do: changeset(struct, params)

  defp validate_email(changeset) do
    unique_constraint(changeset, :email, message: "Sorry, that email has already been taken.")
  end

  defp clear_value(_), do: nil

  defp validate_phone_number(changeset) do
    validate_format(
      changeset,
      :phone_number,
      ~r/^[0-9]{10}$/,
      message: "Phone number is not in a valid format."
    )
  end

  defp validate_accept_tnc(changeset, %{"accept_tnc" => "true"}), do: changeset

  defp validate_accept_tnc(changeset, _) do
    add_error(changeset, :accept_tnc, "You must consent to these terms to receive SMS alerts.",
      validation: :required
    )
  end

  defp clean_phone_number(nil), do: nil
  defp clean_phone_number(value), do: String.replace(value, ~r/\D/, "")

  defp clean_email(struct) do
    struct
    |> update_change(:email, &String.trim/1)
    |> update_change(:email, &lowercase_email/1)
  end

  defp lowercase_email(nil), do: ""
  defp lowercase_email(value), do: String.downcase(value)

  def opt_in_phone_number(%__MODULE__{phone_number: nil}), do: {:ok, nil}

  def opt_in_phone_number(%__MODULE__{phone_number: phone_number}) do
    phone_number
    |> ExAws.SNS.opt_in_phone_number()
    |> AwsClient.request()
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
      Multi.run(multi, user_id, fn _repo, _changes ->
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

  @spec get(id()) :: t() | nil
  def get(id), do: Repo.get(__MODULE__, id)

  @spec for_email(String.t()) :: t | nil
  def for_email(email) do
    email =
      email
      |> String.trim()
      |> lowercase_email()

    Repo.get_by(__MODULE__, email: email)
  end

  @spec wrap_id(__MODULE__.t() | String.t()) :: __MODULE__.t()
  def wrap_id(%__MODULE__{} = user), do: user
  def wrap_id(user_id), do: %__MODULE__{id: user_id}

  @spec admin?(t()) :: boolean
  def admin?(%__MODULE__{role: "admin"}), do: true
  def admin?(_user), do: false

  @spec make_admin(t, t | id) :: {:ok, t} | {:error, any}
  def make_admin(user, originator) do
    update_account(user, %{"role" => "admin"}, originator)
  end

  @spec make_not_admin(t, t | id) :: {:ok, t} | {:error, any}
  def make_not_admin(user, originator) do
    update_account(user, %{"role" => "user"}, originator)
  end

  def inside_opt_out_freeze_window?(%__MODULE__{sms_opted_out_at: nil}), do: false

  def inside_opt_out_freeze_window?(%__MODULE__{sms_opted_out_at: sms_opted_out_at}),
    do: Date.diff(Date.utc_today(), DateTime.to_date(sms_opted_out_at)) <= 30

  @doc """
  Returns the email address for the given user.

  ## Examples

      iex> User.email(%User{email: "user@example.com"})
      "user@example.com"
  """
  @spec email(t()) :: String.t()
  def email(%__MODULE__{email: email}), do: email

  @doc """
  Returns the phone number for the given user.

  ## Examples

      iex> User.phone_number(%User{phone_number: "5551234567"})
      "5551234567"
  """
  @spec phone_number(t()) :: String.t() | nil
  def phone_number(%__MODULE__{phone_number: phone_number}), do: phone_number

  defp normalize_papertrail_result({:ok, %{model: user}}), do: {:ok, user}
  defp normalize_papertrail_result(result), do: result
end
