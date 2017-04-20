defmodule MbtaServer.AlertProcessor.Model.Subscription do
  @moduledoc """
  Set of criteria on which a user wants to be sent alerts.
  """
  alias MbtaServer.User
  alias MbtaServer.AlertProcessor.Model.InformedEntity

  @type t :: %__MODULE__{
    alert_priority_type: atom,
    user_id: String.t
  }

  @type id :: String.t

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "subscriptions" do
    belongs_to :user, User, type: :binary_id
    has_many :informed_entities, InformedEntity
    field :alert_priority_type, MbtaServer.AlertProcessor.AtomType

    timestamps()
  end

  @permitted_fields ~w(alert_priority_type user_id)a
  @required_fields ~w(alert_priority_type user_id)a

  @doc """
  Changeset for persisting a Subscription
  """
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @permitted_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:alert_priority_type, ["low", "medium", "high"])
  end
end
