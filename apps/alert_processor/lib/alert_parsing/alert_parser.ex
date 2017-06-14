defmodule AlertProcessor.AlertParser do
  @moduledoc """
  Module used to parse alerts from api and transform into Alert structs and pass along
  relevant information to subscription filter engine.
  """
  alias AlertProcessor.{AlertCache, AlertsClient, ApiClient, Helpers.StringHelper, HoldingQueue, Parser, ServiceInfoCache, SubscriptionFilterEngine}
  alias AlertProcessor.Model.{Alert, InformedEntity, Notification}

  @behaviour Parser

  @doc """
  process_alerts/0 entry point for fetching json data from api and, transforming, storing and passing to
  subscription engine to process before sending.
  """
  @spec process_alerts() :: [{:ok, [Notification.t]}]
  def process_alerts() do
    with {:ok, alerts} <- AlertsClient.get_alerts(),
         facilities <- ApiClient.facilities() do
      {alerts_needing_notifications, alert_ids_to_clear_notifications} =
        {alerts, facilities}
        |> map_facilities()
        |> parse_alerts()
        |> AlertCache.update_cache()

      HoldingQueue.remove_notifications(alert_ids_to_clear_notifications)
      Enum.map(alerts_needing_notifications, &SubscriptionFilterEngine.process_alert/1)
    end
  end

  defp map_facilities({alerts, facilities}) do
    facilities_map = for f <- facilities, into: %{} do
      %{"attributes" => %{"type" => facility_type}, "id" => id} = f
      {id, facility_type}
    end
    {alerts, facilities_map}
  end

  defp parse_alerts({alerts, facilities_map}) do
    for alert_json <- alerts, alert = parse_alert(alert_json, facilities_map), into: %{} do
      {alert.id, alert}
    end
  end

  defp parse_alert(%{
    "active_period" => active_periods,
    "description_text" => description_text_translations,
    "effect_name" => effect_name,
    "id" => alert_id,
    "informed_entity" => informed_entities,
    "service_effect_text" => service_effect_text_translations,
    "severity_name" => severity,
    "short_description_text" => header_text_translations
  } = alert_data, facilities_map) do
    %Alert{
      active_period: parse_active_periods(active_periods),
      description: parse_translation(description_text_translations),
      effect_name: StringHelper.split_capitalize(effect_name, "_"),
      header: parse_translation(header_text_translations),
      id: to_string(alert_id),
      informed_entities: parse_informed_entities(informed_entities, facilities_map),
      last_push_notification: Map.get_lazy(alert_data, "last_push_notification_timestamp", fn -> Map.get(alert_data, "created_timestamp") end) |> parse_datetime(),
      service_effect: parse_translation(service_effect_text_translations),
      severity: severity |> String.downcase |> String.to_existing_atom,
    }
  end

  defp parse_alert(_, _) do
    nil
  end

  defp parse_datetime(datetime) do
    {:ok, dt} = DateTime.from_unix(datetime)
    dt
  end

  defp parse_active_periods(active_periods) do
    Enum.map(active_periods, &parse_active_period(&1))
  end

  defp parse_active_period(active_period) do
    active_period
    |> Map.new(fn({k, v}) ->
        with {:ok, datetime} <- DateTime.from_unix(v) do
          {String.to_existing_atom(k), datetime}
        else
          _ -> {String.to_existing_atom(k), nil}
        end
      end)
    |> Map.put_new(:end, nil)
  end

  defp parse_informed_entities(informed_entities, facilities_map) do
    InformedEntity.queryable_fields
    Enum.map(informed_entities, fn(ie) ->
      struct_params = parse_informed_entity(ie)
      informed_entity = struct(InformedEntity, struct_params)
      with {:facility_id, facility_id} <- Enum.find(struct_params, &(elem(&1, 0) == :facility_id)),
           %{^facility_id => facility_type} <- facilities_map do
        %{informed_entity | facility_type: facility_type |> String.downcase() |> String.to_existing_atom()}
      else
        _ -> informed_entity
      end
    end)
  end

  defp parse_informed_entity(informed_entity) do
    Enum.reduce(informed_entity, %{}, fn({k, v}, acc) ->
      case k do
        "trip" ->
          Map.merge(acc, parse_trip(v))
        "stop_id" ->
          Map.merge(acc, parse_stop(v))
        "route_id" ->
          Map.merge(acc, parse_route(v))
        "facility_id" ->
          Map.put(acc, :facility_id, v)
        "direction_id" ->
          Map.put(acc, :direction_id, v)
        _ ->
          acc
      end
    end)
  end

  defp parse_trip(trip) do
    case trip do
      %{"trip_id" => trip, "direction_id" => direction_id} -> %{trip: trip, direction_id: direction_id}
      %{"trip_id" => trip} -> %{trip: trip}
      _ -> %{}
    end
  end

  defp parse_stop(stop_id) do
    stop =
      case ServiceInfoCache.get_parent_stop_id(stop_id) do
        {:ok, parent_stop_id} when is_binary(parent_stop_id) -> parent_stop_id
        _ -> stop_id
      end
     %{stop: stop}
  end

  defp parse_route("CR-" <> _ = route_id) do
    %{route: route_id, route_type: 2}
  end
  defp parse_route("Boat-" <> _ = route_id) do
    %{route: route_id, route_type: 4}
  end
  defp parse_route(route_id) do
    {:ok, route} = ServiceInfoCache.get_route(route_id)
    case route do
      %{route_type: route_type} -> %{route: route_id, route_type: route_type}
      _ -> %{route: route_id}
    end
  end

  defp parse_translation(translations) do
    case Enum.find(translations, &(&1["translation"]["language"] == "en")) do
      %{"translation" => %{"language" => "en", "text" => text}} -> text
      _ -> nil
    end
  end
end
