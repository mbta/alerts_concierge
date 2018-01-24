defmodule ConciergeSite.AlertFactory do
  @moduledoc """
  Simplify generation of alerts
  """

  alias AlertProcessor.{Model.InformedEntity, Model.Alert}

  @base_alert %Alert{header: "", id: "1", effect_name: "", last_push_notification: DateTime.utc_now(),
                     informed_entities: [], active_period: []}
  @base_informed_entity %InformedEntity{activities: InformedEntity.default_entity_activities()}

  defp add_informed_entity(alert, subscription, activities, trips) do
    informed_entitities = @base_informed_entity
    |> add_route_type(subscription)
    |> add_route(subscription)
    |> add_activities(activities)
    |> add_direction(subscription)
    |> add_stops(subscription)
    |> add_trips(trips)

    %{alert | informed_entities: alert.informed_entities ++ informed_entitities}
  end

  defp add_stops(informed_entity, %{origin: origin, destination: destination}) do
    [%{informed_entity | stop: origin}, %{informed_entity | stop: destination}]
  end
  defp add_stops(informed_entity, _), do: [informed_entity]

  defp add_trips([informed_entity | _], nil), do: [informed_entity]
  defp add_trips([informed_entity | _], trips), do: Enum.map(trips, & %{informed_entity | trip: &1})

  defp time_to_datetime(time) do
    {hour, minute, second} = Time.to_erl(time)
    %{year: year, day: day, month: month} = Date.utc_today()
    %DateTime{year: year, month: month, day: day, zone_abbr: "UTC", hour: hour, minute: minute, second: second,
              microsecond: {0, 0}, utc_offset: 0, std_offset: 0, time_zone: "Etc/UTC"}
  end

  defp add_direction(informed_entity, subscription), do: %{informed_entity | direction_id: subscription.direction_id}

  defp add_route(informed_entity, subscription), do: %{informed_entity | route: subscription.route}

  defp add_route_type(informed_entity, %{type: :subway}), do: %{informed_entity | route_type: 1}
  defp add_route_type(informed_entity, %{type: :commuter_rail}), do: %{informed_entity | route_type: 2}
  defp add_route_type(informed_entity, %{type: :bus}), do: %{informed_entity | route_type: 3}
  defp add_route_type(informed_entity, %{type: :ferry}), do: %{informed_entity | route_type: 4}

  defp add_activities(informed_entity, nil), do: informed_entity
  defp add_activities(informed_entity, activities), do: %{informed_entity | activities: activities}

  defp active_period(alert, subscription) do
    %{alert | active_period: alert.active_period ++ [%{start: time_to_datetime(subscription.start_time),
                                                       end: time_to_datetime(subscription.end_time)}]}
  end

  defp severity(alert, %{alert_priority_type: :high}), do: %{alert | severity: :minor}
  defp severity(alert, %{alert_priority_type: :medium}), do: %{alert | severity: :moderate}
  defp severity(alert, %{alert_priority_type: :low}), do: %{alert | severity: :severe}

  def alert(:all, subscription, activities, trips) do
    @base_alert
    |> severity(subscription)
    |> add_informed_entity(subscription, activities, trips)
    |> active_period(subscription)
  end

  def alert(:not_route, subscription, activities, trips) do
    alert(:all, %{subscription | route: "Not"}, activities, trips)
  end
end
