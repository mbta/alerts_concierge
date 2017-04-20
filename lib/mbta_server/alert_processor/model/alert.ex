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
    severity: String.t
  }

  @severity_values %{
    "Minor" => 1,
    "Moderate" => 2,
    "Severe" => 3
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
        low: 1, medium: 2, high: 3
      },
      "Extra Service" => %{
        low: 1, medium: 1
      },
      "Schedule Change" => %{
        low: 1, medium: 1, high: 1
      },
      "Service Change" => %{
        low: 1, medium: 2, high: 3
      },
      "Shuttle" => %{
        low: 1, medium: 1, high: 1
      },
      "Station Closure" => %{
        low: 1, medium: 1, high: 1
      },
      "Station Issue" => %{
        low: 1, medium: 2, high: 3
      },
      "Suspension" => %{
        low: 1, medium: 1, high: 1
      }
    },
    "Commuter Rail" => %{
      "Cancellation" => %{
        low: 1, medium: 1, high: 1
      },
      "Delay" => %{
        low: 1, medium: 1
      },
      "Extra Service" => %{
        low: 1
      },
      "Schedule Change" => %{
        low: 1, medium: 1, high: 1
      },
      "Service Change" => %{
        low: 1, medium: 2, high: 3
      },
      "Shuttle" => %{
        low: 1, medium: 1, high: 1
      },
      "Station Closure" => %{
        low: 1, medium: 1, high: 1
      },
      "Suspension" => %{
        low: 1, medium: 1, high: 1
      },
      "Track Change" => %{
        low: 1
      }
    },
    "Bus" => %{
      "Delay" => %{
        low: 1, medium: 2, high: 3
      },
      "Detour" => %{
        low: 1, medium: 1, high: 1
      },
      "Extra Service" => %{
        low: 1
      },
      "Schedule Change" => %{
        low: 1, medium: 1, high: 1
      },
      "Service Change" => %{
        low: 1, medium: 2, high: 3
      },
      "Snow Route" => %{
        low: 1, medium: 1, high: 1
      },
      "Stop Closure" => %{
        low: 1, medium: 1
      },
      "Stop Move" => %{
        low: 1
      },
      "Suspension" => %{
        low: 1, medium: 1, high: 1
      }
    },
    "Ferry" => %{
      "Cancellation" => %{
        low: 1, medium: 1, high: 1
      },
      "Delay" => %{
        low: 1, medium: 1
      },
      "Dock Closure" => %{
        low: 1, medium: 1, high: 1
      },
      "Dock Issue" => %{
        low: 1, medium: 2, high: 3
      },
      "Extra Service" => %{
        low: 1, medium: 1
      },
      "Schedule Change" => %{
        low: 1, medium: 1, high: 1
      },
      "Service Change" => %{
        low: 1, medium: 2, high: 3
      },
      "Shuttle" => %{
        low: 1, medium: 1, high: 1
      },
      "Suspension" => %{
        low: 1, medium: 1, high: 1
      },
    },
    "Systemwide" => %{
      "Delay" => %{
        low: 1, medium: 1, high: 1
      },
      "Extra Service" => %{
        low: 1, medium: 1
      },
      "Policy Change" => %{
        low: 1, medium: 1, high: 1
      },
      "Service Change" => %{
        low: 1, medium: 1, high: 1
      },
      "Suspension" => %{
        low: 1, medium: 1, high: 1
      },
      "Amber Alert" => %{
        low: 1, medium: 1, high: 1
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
  @spec priority_min_value(String.t, String.t, atom) :: integer | nil
  def priority_min_value(route_type, effect_name, alert_priority_type) do
    @severity_map[route_type][effect_name][alert_priority_type]
  end

  @doc """
  return the numeric value for severity for a given alert.
  """
  @spec severity_value(__MODULE__.t) :: integer
  def severity_value(%__MODULE__{severity: severity}) do
    @severity_values[severity]
  end
end
