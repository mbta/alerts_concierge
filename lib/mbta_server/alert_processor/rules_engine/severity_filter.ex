defmodule MbtaServer.AlertProcessor.SeverityFilter do
  @moduledoc """
  Filter users based on severity determined by a combination of
  severity provided in the alert and effect name.
  """

  import Ecto.Query
  alias MbtaServer.Repo
  alias MbtaServer.AlertProcessor.{Model.Alert, Model.Subscription}

  @doc """
  filter/1 takes a tuple of the remaining users to be considered and
  an alert and returns the now remaining users to be considered
  which have a matching subscription based on severity and
  an alert to pass through to the next filter. Otherwise the flow is
  shortcircuited if the user id list provided is missing or empty.
  """
  @spec filter({:ok, [Subscription.id], Alert.t}) :: {:ok, [Subscription.id], Alert.t}
  def filter({:ok, [], %Alert{} = alert}), do: {:ok, [], alert}
  def filter({:ok, previous_subscription_ids, %Alert{} = alert}) do
    subscriptions = Repo.all(
      from s in Subscription,
      join: ie in assoc(s, :informed_entities),
      preload: [:informed_entities],
      where: s.id in ^previous_subscription_ids
    )

    subscription_ids = Enum.filter_map(subscriptions, &send_alert?(&1, alert), & &1.id)

    {:ok, subscription_ids, alert}
  end

  @spec send_alert?(Subscription.t, Alert.t) :: boolean
  defp send_alert?(subscription, alert) do
    Enum.any?(severity_comparison_results(subscription, alert))
  end

  defp matching_route_types(subscription, alert) do
    subscription_route_types = MapSet.new(["Systemwide" | route_types_for_informed_entities(subscription)])
    alert_route_types = MapSet.new(route_types_for_informed_entities(alert))
    subscription_route_types |> MapSet.intersection(alert_route_types) |> MapSet.to_list
  end

  defp route_types_for_informed_entities(%{informed_entities: informed_entities}) do
    Enum.map(informed_entities, fn(informed_entity) ->
      case informed_entity do
        %{route_type: _, route: nil} -> "Systemwide"
        %{route_type: route_type, route: _} -> Alert.route_string(route_type)
        %{route_type: _} -> "Systemwide"
      end
    end)
  end

  defp severity_comparison_results(subscription, alert) do
    Enum.map(matching_route_types(subscription, alert), fn(route_type) ->
      case Alert.priority_min_value(route_type, alert.effect_name, subscription.alert_priority_type) do
        nil -> false
        min_priority -> min_priority <= Alert.severity_value(alert)
      end
    end)
  end
end
