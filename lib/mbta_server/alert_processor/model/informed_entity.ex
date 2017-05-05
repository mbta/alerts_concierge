defmodule MbtaServer.AlertProcessor.Model.InformedEntity do
  @moduledoc """
  Entity to map to the informed entity information provided in an
  Alert used to match to a subscription.
  """

  alias MbtaServer.AlertProcessor.Model.Subscription

  @type t :: %__MODULE__{
    direction_id: integer,
    facility_type: :elevator | :escalator,
    route: String.t,
    route_type: integer,
    subscription_id: String.t,
    stop: String.t,
    trip: String.t
  }

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "informed_entities" do
    belongs_to :subscription, Subscription, type: :binary_id
    field :direction_id, :integer
    field :facility_type, MbtaServer.AlertProcessor.AtomType
    field :route, :string
    field :route_type, :integer
    field :stop, :string
    field :trip, :string

    timestamps()
  end

  def queryable_fields do
    [:direction_id, :facility_type, :route, :route_type, :stop, :trip]
  end
end
