defmodule MbtaServer.AlertProcessor.Model.Alert do
  @moduledoc """
  Representation of alert received from MBTA /alerts endpoint
  """
  defstruct [:effect_name, :id, :header, :informed_entities, :severity]

  @type t :: %__MODULE__{
    effect_name: String.t,
    header: String.t,
    id: String.t,
    informed_entities: [map],
    severity: atom
  }

  @route_types %{
    0 => "Subway",
    1 => "Subway",
    2 => "Commuter Rail",
    3 => "Bus",
    4 => "Ferry"
  }

  @severity_map %{
    "Subway" => %{
      "Delay" => %{
        minor: 3,
        moderate: 2,
        severe: 1
      },
      "Extra Service" => %{
        moderate: 1,
        severe: 1
      },
      "Schedule Change" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Service Change" => %{
        minor: 3,
        moderate: 2,
        severe: 1
      },
      "Shuttle" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Station Closure" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Station Issue" => %{
        minor: 3,
        moderate: 2,
        severe: 1
      },
      "Suspension" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      }
    },
    "Commuter Rail" => %{
      "Cancellation" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Delay" => %{
        moderate: 1,
        severe: 1
      },
      "Extra Service" => %{
        severe: 1
      },
      "Schedule Change" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Service Change" => %{
        minor: 3,
        moderate: 2,
        severe: 1
      },
      "Shuttle" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Station Closure" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Suspension" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Track Change" => %{
        minor: 1
      }
    },
    "Bus" => %{
      "Delay" => %{
        minor: 3,
        moderate: 2,
        severe: 1
      },
      "Detour" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Extra Service" => %{
        severe: 1
      },
      "Schedule Change" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Service Change" => %{
        minor: 3,
        moderate: 2,
        severe: 1
      },
      "Snow Route" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Stop Closure" => %{
        moderate: 1,
        severe: 1
      },
      "Stop Move" => %{
        severe: 1
      },
      "Suspension" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      }
    },
    "Ferry" => %{
      "Cancellation" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Delay" => %{
        moderate: 1,
        severe: 1
      },
      "Dock Closure" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Dock Issue" => %{
        minor: 3,
        moderate: 2,
        severe: 1
      },
      "Extra Service" => %{
        moderate: 1,
        severe: 1
      },
      "Schedule Change" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Service Change" => %{
        minor: 3,
        moderate: 2,
        severe: 1
      },
      "Shuttle" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Suspension" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
    },
    "Systemwide" => %{
      "Delay" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Extra Service" => %{
        moderate: 1,
        severe: 1
      },
      "Policy Change" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Service Change" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Suspension" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      },
      "Amber Alert" => %{
        minor: 1,
        moderate: 1,
        severe: 1
      }
    }
  }

  @doc """
  convert route type numeric representation to the string representation.
  """
  @spec route_string(integer) :: String.t
  def route_string(route_type) do
    @route_types[route_type]
  end

  @doc """
  convert route type and effect name from an alert and a user's alert priority type
  into the minimum value needed to send a notification.
  """
  @spec priority_value(String.t, String.t, atom) :: integer | nil
  def priority_value(route_type, effect_name, severity) do
    @severity_map[route_type][effect_name][severity]
  end

  @doc """
  return the numeric value for severity for a given alert. the lower the number
  the more severe.
  """
  @spec severity_value(__MODULE__.t) :: integer | nil
  def severity_value(%__MODULE__{severity: severity, effect_name: effect_name, informed_entities: informed_entities}) do
      informed_entities
      |> Enum.map(fn(informed_entity) ->
        mode =
          case informed_entity do
            %{route_type: _, route: nil} -> "Systemwide"
            %{route_type: route_type, route: _} -> route_string(route_type)
            %{route_type: _} -> "Systemwide"
          end
        priority_value(mode, effect_name, severity)
      end)
      |> Enum.min
  end
end
