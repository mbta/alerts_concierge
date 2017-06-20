defmodule AlertProcessor.Model.InformedEntity do
  @moduledoc """
  Entity to map to the informed entity information provided in an
  Alert used to match to a subscription.
  """

  alias AlertProcessor.Model.Subscription

  @type facility_type :: :elevator | :escalator

  @type t :: %__MODULE__{
    direction_id: integer,
    facility_type: facility_type,
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
    field :facility_type, AlertProcessor.AtomType
    field :route, :string
    field :route_type, :integer
    field :stop, :string
    field :trip, :string

    timestamps()
  end

  @doc """
  function used to make sure subscription type atoms are available in runtime
  for String.to_existing_atom calls.
  """
  def facility_types do
    [:elevator, :escalator]
  end

  def queryable_fields do
    [:direction_id, :facility_type, :route, :route_type, :stop, :trip]
  end

  @spec entity_type(__MODULE__.t) :: :amenity | :stop | :trip | :route | :mode | :unknown
  def entity_type(%__MODULE__{stop: s, facility_type: ft}) when is_binary(s) and is_atom(ft) and not is_nil(ft), do: :amenity
  def entity_type(%__MODULE__{route: r, route_type: rt, stop: s}) when is_binary(r) and is_number(rt) and is_binary(s), do: :stop
  def entity_type(%__MODULE__{trip: t}) when is_binary(t), do: :trip
  def entity_type(%__MODULE__{route: r, route_type: rt}) when is_binary(r) and is_number(rt), do: :route
  def entity_type(%__MODULE__{route_type: rt}) when is_number(rt), do: :mode
  def entity_type(_), do: :unknown
end
