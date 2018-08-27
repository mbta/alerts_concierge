defmodule AlertProcessor.Model.User do
  @moduledoc """
  User struct and functions
  """
  @type id :: String.t()
  @type communication_mode :: :email | :sms | :none
  @type t :: %__MODULE__{
          id: id,
          email: String.t(),
          phone_number: String.t(),
          role: String.t(),
          digest_opt_in: boolean,
          sms_opted_out_at: DateTime.t(),
          communication_mode: communication_mode
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
    field(:sms_opted_out_at, :utc_datetime)
    field(:communication_mode, :string, null: false, default: "email")
    field(:password, :string, virtual: true)
    field(:sms_toggle, :boolean, virtual: true)

    timestamps()
  end

  @permitted_fields ~w(email phone_number role password digest_opt_in sms_opted_out_at communication_mode)a
  @required_fields ~w(email password)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}, required_fields \\ []) do
    struct
    |> cast(params, @permitted_fields)
    |> update_change(:email, &String.downcase/1)
    |> validate_required(required_fields)
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
  Deletes all the version from papertrail, then the subscriptions and trips followed by the user record
  """
  def delete(user) do
    Ecto.Adapters.SQL.query!(Repo, "DELETE FROM versions WHERE originator_id = $1", [
      UUID.string_to_binary!(user.id)
    ])

    Repo.delete_all(from(s in Subscription, where: s.user_id == ^user.id))
    Repo.delete_all(from(t in Trip, where: t.user_id == ^user.id))
    Repo.delete(user)
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
    params =
      case params do
        %{"sms_toggle" => "false"} ->
          Map.put(params, "phone_number", nil)

        %{"sms_toggle" => "true"} ->
          Map.put(
            params,
            "phone_number",
            String.replace(params["phone_number"] || "", ~r/\D/, "")
          )

        _ ->
          params
      end

    struct
    |> changeset(params, @required_fields)
    |> validate_format(:email, ~r/@/, message: "Please enter a valid email address.")
    |> unique_constraint(:email, message: "Sorry, that email has already been taken.")
    |> validate_length(
      :password,
      min: 6,
      message: "Password must be at least six characters long."
    )
    |> validate_format(
      :password,
      ~r/[^a-zA-Z\s:]{1}/,
      message: "Password must contain one number or special character (? & % $ # !, etc)."
    )
    |> validate_format(
      :phone_number,
      ~r/^[0-9]{10}$/,
      message: "Phone number is not in a valid format."
    )
    |> hash_password()
  end

  @doc """
  Builds changeset for updating an existing user account
  """
  def update_account_changeset(struct, params \\ %{}) do
    params =
      case params do
        %{"sms_toggle" => "false"} ->
          Map.put(params, "phone_number", nil)

        %{"sms_toggle" => "true"} ->
          Map.put(
            params,
            "phone_number",
            String.replace(params["phone_number"] || "", ~r/\D/, "")
          )

        _ ->
          params
      end

    struct
    |> changeset(params, [])
    |> validate_format(
      :phone_number,
      ~r/^[0-9]{10}$/,
      message: "Phone number is not in a valid format."
    )
  end

  defp update_password_changeset(struct, params) do
    struct
    |> changeset(params, ~w(password)a)
    |> validate_length(
      :password,
      min: 6,
      message: "Password must be at least six characters long."
    )
    |> validate_format(
      :password,
      ~r/[^a-zA-Z\s:]{1}/,
      message: "Password must contain one number or special character (? & % $ # !, etc)."
    )
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
    user = Repo.get_by(__MODULE__, email: String.downcase(email))

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
  Returns user ids based on a list of phone numbers
  """
  def ids_by_phone_numbers(phone_numbers) do
    Repo.all(from(u in __MODULE__, where: u.phone_number in ^phone_numbers, select: u.id))
  end

  @doc """
  Takes a list of user ids and puts on vacation mode ending in the year 9999
  """
  def remove_users_phone_number(user_ids, origin) do
    user_ids
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {user_id, index}, acc ->
      Multi.run(acc, {:user, index}, fn _ ->
        __MODULE__
        |> Repo.get(user_id)
        |> update_account_changeset(%{phone_number: nil})
        |> PaperTrail.update(origin: origin)
      end)
    end)
    |> Repo.transaction()
    |> normalize_papertrail_result()
  end

  defp normalize_papertrail_result({:ok, %{model: user}}), do: {:ok, user}
  defp normalize_papertrail_result(result), do: result

  @spec for_email(String.t()) :: t | nil
  def for_email(email) do
    Repo.get_by(__MODULE__, email: email)
  end

  @spec find_by_email_search(String.t()) :: [t]
  def find_by_email_search(query) do
    Repo.all(from(u in __MODULE__, where: like(u.email, ^"%#{query}%")))
  end

  @spec find_by_phone_number_search(String.t()) :: [t]
  def find_by_phone_number_search(query) do
    Repo.all(from(u in __MODULE__, where: like(u.phone_number, ^"%#{query}%")))
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
end
