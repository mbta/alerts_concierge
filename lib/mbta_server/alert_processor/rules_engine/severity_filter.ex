defmodule MbtaServer.AlertProcessor.SeverityFilter do
  @moduledoc """
  Filter users based on severity determined by a combination of
  severity provided in the alert and effect name.
  """

  import Ecto.Query
  alias MbtaServer.Repo
  alias MbtaServer.AlertProcessor.{Model.Alert, Model.Subscription}

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
        "low" => 1, "medium" => 2, "high" => 3
      },
      "Extra Service" => %{
        "low" => 1, "medium" => 1
      },
      "Schedule Change" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Service Change" => %{
        "low" => 1, "medium" => 2, "high" => 3
      },
      "Shuttle" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Station Closure" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Station Issue" => %{
        "low" => 1, "medium" => 2, "high" => 3
      },
      "Suspension" => %{
        "low" => 1, "medium" => 1, "high" => 1
      }
    },
    "Commuter Rail" => %{
      "Cancellation" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Delay" => %{
        "low" => 1, "medium" => 1
      },
      "Extra Service" => %{
        "low" => 1
      },
      "Schedule Change" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Service Change" => %{
        "low" => 1, "medium" => 2, "high" => 3
      },
      "Shuttle" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Station Closure" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Suspension" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Track Change" => %{
        "low" => 1
      }
    },
    "Bus" => %{
      "Delay" => %{
        "low" => 1, "medium" => 2, "high" => 3
      },
      "Detour" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Extra Service" => %{
        "low" => 1
      },
      "Schedule Change" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Service Change" => %{
        "low" => 1, "medium" => 2, "high" => 3
      },
      "Snow Route" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Stop Closure" => %{
        "low" => 1, "medium" => 1
      },
      "Stop Move" => %{
        "low" => 1
      },
      "Suspension" => %{
        "low" => 1, "medium" => 1, "high" => 1
      }
    },
    "Ferry" => %{
      "Cancellation" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Delay" => %{
        "low" => 1, "medium" => 1
      },
      "Dock Closure" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Dock Issue" => %{
        "low" => 1, "medium" => 2, "high" => 3
      },
      "Extra Service" => %{
        "low" => 1, "medium" => 1
      },
      "Schedule Change" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Service Change" => %{
        "low" => 1, "medium" => 2, "high" => 3
      },
      "Shuttle" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Suspension" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
    },
    "Systemwide" => %{
      "Delay" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Extra Service" => %{
        "low" => 1, "medium" => 1
      },
      "Policy Change" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Service Change" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Suspension" => %{
        "low" => 1, "medium" => 1, "high" => 1
      },
      "Amber Alert" => %{
        "low" => 1, "medium" => 1, "high" => 1
      }
    }
  }

  @doc """
  filter/1 takes a tuple of the remaining users to be considered and
  an alert and returns the now remaining users to be considered
  which have a matching subscription based on severity and
  an alert to pass through to the next filter. Otherwise the flow is
  shortcircuited if the user id list provided is missing or empty.
  """
  @spec filter({:ok, [String.t], Alert.t}) :: {:ok, [String.t], Alert.t}
  def filter({:ok, [], %Alert{} = alert}), do: {:ok, [], alert}
  def filter({:ok, previous_subscription_ids, %Alert{} = alert}) do
    subscriptions = Repo.all(
      from s in Subscription,
      join: ie in assoc(s, :informed_entities),
      preload: [:informed_entities],
      where: s.id in ^previous_subscription_ids
    )

    subscription_ids = Enum.filter_map(subscriptions, &send_alert?(&1, alert), &Map.get(&1, :id))

    {:ok, subscription_ids, alert}
  end

  @spec send_alert?(Subscription.t, Alert.t) :: true | false
  defp send_alert?(subscription, alert) do
    Enum.any?(severity_map_results(subscription, alert))
  end

  defp route_types(subscription, alert) do
    subscription_route_types = MapSet.new(route_types(subscription) ++ ["Systemwide"])
    alert_route_types = MapSet.new(route_types(alert))
    subscription_route_types |> MapSet.intersection(alert_route_types) |> MapSet.to_list
  end

  defp route_types(%{informed_entities: informed_entities}) do
    Enum.map(informed_entities, fn(x) ->
      case x do
        %{route_type: _, route: nil} -> "Systemwide"
        %{route_type: route_type, route: _} -> @route_types[route_type]
        %{route_type: _} -> "Systemwide"
      end
    end)
  end

  defp severity_map_results(subscription, alert) do
    Enum.map(route_types(subscription, alert), fn(route_type) ->
      case @severity_map[route_type][alert.effect_name][subscription.alert_priority_type] do
        nil -> false
        min_priority -> min_priority <= Alert.severity_value(alert)
      end
    end)
  end
end
