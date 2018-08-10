defmodule AlertProcessor.Model.Route do
  @moduledoc """
  Module used for storing information
  about different routes for use
  when displaying subscriptions
  """

  defstruct [
    :direction_names,
    :headsigns,
    :long_name,
    :order,
    :route_id,
    :route_type,
    :short_name,
    stop_list: []
  ]

  @type direction_id :: integer
  @type headsigns :: %{
          0 => [String.t()],
          1 => [String.t()]
        }
  @type route_id :: String.t()
  @type route_type :: 0 | 1 | 2 | 3 | 4
  @type stop_id :: String.t()
  @type stop :: {String.t(), stop_id, {float(), float()}}

  @type t :: %__MODULE__{
          direction_names: [String.t()],
          headsigns: headsigns,
          long_name: String.t(),
          route_id: route_id,
          route_type: route_type,
          short_name: String.t(),
          stop_list: [stop],
          order: integer
        }

  def name(%__MODULE__{long_name: "", short_name: name}), do: name
  def name(%__MODULE__{long_name: name}), do: name

  @spec bus_short_name(t()) :: String.t()
  def bus_short_name(%__MODULE__{short_name: short_name}) do
    if String.starts_with?(short_name, "SL") do
      "Silver Line #{short_name}"
    else
      "Route #{short_name}"
    end
  end
end
