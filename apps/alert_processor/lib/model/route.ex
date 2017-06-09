defmodule AlertProcessor.Model.Route do
  defstruct [:direction_names, :long_name, :route_id, :route_type, :stop_list]

  @type route_id :: String.t
  @type route_type :: 0 | 1 | 2 | 3 | 4
  @type stop :: {String.t, String.t}

  @type t :: %__MODULE__{
    direction_names: [String.t],
    long_name: String.t,
    route_id: route_id,
    route_type: route_type,
    stop_list: [stop]
  }
end
