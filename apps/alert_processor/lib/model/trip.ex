defmodule AlertProcessor.Model.Trip do
  @moduledoc """
  Module used for storing information
  about trips for displaying
  """

  defstruct [:arrival_time, :departure_time, :destination, :direction_id, :route, :origin, :trip_number]

  alias AlertProcessor.Model.Route

  @type id :: String.t
  @type t :: %__MODULE__{
    arrival_time: Time.t,
    departure_time: Time.t,
    destination: Route.stop,
    direction_id: Route.direction_id,
    route: Route.t,
    origin: Route.stop,
    trip_number: id
  }
end
