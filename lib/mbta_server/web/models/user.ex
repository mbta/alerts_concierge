defmodule MbtaServer.User do
  @moduledoc """
  User struct and functions
  """
  @type t :: %__MODULE__{
    id: String.t,
    email: String.t,
    phone_number: String.t,
    role: String.t,
    vacation_start: NaiveDateTime.t,
    vacation_end: NaiveDateTime.t,
    do_not_disturb_start: Time.t,
    do_not_disturb_end: Time.t,
  }

  use Ecto.Schema
  import Ecto.Changeset
  alias MbtaServer.AlertProcessor.Model.Subscription

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    has_one :subscription, Subscription
    field :email, :string
    field :phone_number, :string
    field :role, :string
    field :vacation_start, :naive_datetime
    field :vacation_end, :naive_datetime
    field :do_not_disturb_start, :time
    field :do_not_disturb_end, :time

    timestamps()
  end

  @permitted_fields ~w(email phone_number role vacation_start
    vacation_end do_not_disturb_start do_not_disturb_end)a
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
