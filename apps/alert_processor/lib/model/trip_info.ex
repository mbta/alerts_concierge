defmodule AlertProcessor.Model.TripInfo do
  @moduledoc """
  Module used for storing information
  about trips for displaying
  """
  defstruct [
    :arrival_time,
    :departure_time,
    :arrival_datetime,
    :departure_datetime,
    :destination,
    :direction_id,
    :route,
    :origin,
    :trip_number,
    selected: false,
    weekend?: false
  ]

  alias AlertProcessor.Model.Route

  @type id :: String.t
  @type t :: %__MODULE__{
    arrival_time: Time.t,
    departure_time: Time.t,
    arrival_datetime: NaiveDateTime.t,
    departure_datetime: NaiveDateTime.t,
    destination: Route.stop,
    direction_id: Route.direction_id,
    route: Route.t,
    origin: Route.stop,
    selected: boolean,
    trip_number: id,
    weekend?: boolean
  }
end
