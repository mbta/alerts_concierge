defmodule AlertProcessor.Model.TripInfo do
  @moduledoc """
  Module used for storing information
  about trips for displaying
  """
  defstruct [:arrival_time, :departure_time, :destination, :direction_id, :route, :origin, :trip_number, selected: false]

  alias AlertProcessor.Model.Route

  @type id :: String.t
  @type t :: %__MODULE__{
    arrival_time: Time.t,
    departure_time: Time.t,
    destination: Route.stop,
    direction_id: Route.direction_id,
    route: Route.t,
    origin: Route.stop,
    selected: boolean,
    trip_number: id
  }
end