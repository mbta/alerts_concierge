defmodule MbtaServer.User do
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
  }

  @type id :: String.t

  use Ecto.Schema
  import Ecto.{Changeset, Query}
  alias MbtaServer.Repo
  alias MbtaServer.AlertProcessor.Model.Subscription
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

    timestamps()
  end

  @permitted_fields ~w(email phone_number role vacation_start
    vacation_end do_not_disturb_start do_not_disturb_end password)a
  @required_fields ~w(email role password)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
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

  defp check_password(user, password) do
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
