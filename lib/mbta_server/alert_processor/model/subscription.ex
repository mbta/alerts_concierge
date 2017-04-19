defmodule MbtaServer.AlertProcessor.Model.Subscription do
  @moduledoc """
  Set of criteria on which a user wants to be sent alerts.
  """

  alias MbtaServer.{AlertProcessor, Repo, User}
  alias AlertProcessor.Model.{InformedEntity, Subscription}
  import Ecto.Query

  @type t :: %__MODULE__{
    alert_priority_type: atom,
    user_id: String.t
  }

  @type id :: String.t

  @alert_priority_type_values %{
    low: 1,
    medium: 2,
    high: 3
  }

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
    |> validate_inclusion(:alert_priority_type, [:low, :medium, :high])
  end

  @doc """
  return the numeric value for a subscription's alert priority type.
  the higher the number, the fewer amount of alerts should be received.
  """
  @spec severity_value(atom) :: integer
  def severity_value(alert_priority_type) do
    @alert_priority_type_values[alert_priority_type]
  end

  @doc """
  Fetches subscriptions with users eager loaded for a list of ids
  """
  @spec fetch_with_user(list) :: [Subscription.t]
  def fetch_with_user(subscription_ids) do
    query = from s in Subscription,
      where: s.id in ^subscription_ids

    query
    |> Repo.all
    |> Repo.preload(:user)
  end
end
