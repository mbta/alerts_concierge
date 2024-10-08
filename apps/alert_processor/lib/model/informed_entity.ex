defmodule AlertProcessor.Model.InformedEntity do
  @moduledoc """
  Entity to map to the informed entity information provided in an
  Alert used to match to a subscription.
  """

  alias AlertProcessor.Model.Subscription

  @type facility_type ::
          :bike_storage
          | :electric_car_chargers
          | :elevator
          | :escalator
          | :parking_area
          | :pick_drop
          | :portable_boarding_lift
          | :tty_phone
          | :elevated_subplatform
  @type schedule ::
          [
            %{
              departure_time: String.t() | nil,
              stop_id: String.t(),
              trip_id: String.t()
            }
          ]
          | nil

  @type t :: %__MODULE__{
          activities: [String.t()],
          direction_id: integer | nil,
          facility_type: facility_type | nil,
          route: String.t() | nil,
          route_type: integer | nil,
          subscription_id: String.t(),
          stop: String.t() | nil,
          trip: String.t() | nil,
          schedule: schedule
        }

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "informed_entities" do
    belongs_to(:subscription, Subscription, type: :binary_id)
    field(:activities, {:array, :string}, default: [])
    field(:direction_id, :integer)
    field(:facility_type, AlertProcessor.AtomType)
    field(:route, :string)
    field(:route_type, :integer)
    field(:stop, :string)
    field(:trip, :string)
    field(:schedule, :map, virtual: true)

    timestamps(type: :utc_datetime)
  end

  @doc """
  function used to make sure subscription type atoms are available in runtime
  for String.to_existing_atom calls.
  """
  def facility_types do
    [
      :bike_storage,
      :electric_car_chargers,
      :elevator,
      :escalator,
      :parking_area,
      :pick_drop,
      :portable_boarding_lift,
      :tty_phone,
      :elevated_subplatform
    ]
  end

  def queryable_fields do
    [:activities, :direction_id, :facility_type, :route, :route_type, :stop, :trip]
  end

  @spec entity_type(__MODULE__.t()) :: :amenity | :stop | :trip | :route | :mode | :unknown
  def entity_type(%__MODULE__{stop: s, facility_type: ft})
      when is_binary(s) and is_atom(ft) and not is_nil(ft),
      do: :amenity

  def entity_type(%__MODULE__{route: r, route_type: rt, stop: s})
      when is_binary(r) and is_number(rt) and is_binary(s),
      do: :stop

  def entity_type(%__MODULE__{trip: t}) when is_binary(t), do: :trip

  def entity_type(%__MODULE__{route: r, route_type: rt}) when is_binary(r) and is_number(rt),
    do: :route

  def entity_type(%__MODULE__{route_type: rt}) when is_number(rt), do: :mode
  def entity_type(_), do: :unknown

  def default_entity_activities, do: ["BOARD", "EXIT", "RIDE"]
end
