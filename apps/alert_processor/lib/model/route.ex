defmodule AlertProcessor.Model.Route do
  defstruct [:direction_names, :headsigns, :long_name, :route_id, :route_type, :stop_list]

  @type headsigns :: %{
    0 => [String.t],
    1 => [String.t]
  }
  @type route_id :: String.t
  @type route_type :: 0 | 1 | 2 | 3 | 4
  @type stop :: {String.t, String.t}

  @type t :: %__MODULE__{
    direction_names: [String.t],
    headsigns: headsigns,
    long_name: String.t,
    route_id: route_id,
    route_type: route_type,
    stop_list: [stop]
  }
end
