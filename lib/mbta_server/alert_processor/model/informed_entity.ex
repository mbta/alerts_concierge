defmodule MbtaServer.AlertProcessor.Model.InformedEntity do
  @moduledoc """
  Entity to map to the informed entity information provided in an
  Alert used to match to a subscription.
  """

  defstruct [:direction_id, :facility, :route, :route_type, :subscription_id, :stop, :trip]

  @type t :: %__MODULE__{
    direction_id: integer,
    facility: String.t,
    route: String.t,
    route_type: integer,
    subscription_id: String.t,
    stop: String.t,
    trip: String.t
  }
end
