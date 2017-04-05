defmodule MbtaServer.User do
  @moduledoc """
  User struct and functions
  """
  @type t :: %__MODULE__{
    id: String.t,
    email: String.t,
    phone_number: String.t,
    role: String.t
  }

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    field :email, :string
    field :phone_number, :string
    field :role, :string

    timestamps()
  end

  @permitted_fields ~w(email phone_number role)a
  @required_fields ~w(email role)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
  end
end
