defmodule AlertProcessor.Model.Trip do
  defstruct [:arrival_time, :departure_time, :destination, :direction_id, :route, :origin, :trip_number]

  alias AlertProcessor.Model.Route

  @type id :: String.t
  @type t :: %__MODULE__{
    arrival_time: Time.t,
    departure_time: Time.t,
    destination: Route.stop_id,
    direction_id: Route.direction_id,
    route: Route.t,
    origin: Route.stop_id,
    trip_number: id
  }
end
