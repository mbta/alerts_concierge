defmodule AlertProcessor.AlertParser do
  @moduledoc """
  Module used to parse alerts from api and transform into Alert structs and pass along
  relevant information to subscription filter engine.
  """
  require Logger
  alias AlertProcessor.{AlertCache, AlertsClient, Helpers.StringHelper, HoldingQueue, Parser, ServiceInfoCache, SubscriptionFilterEngine}
  alias AlertProcessor.Model.{Alert, InformedEntity, Notification, SavedAlert}

  @behaviour Parser

  @doc """
  process_alerts/0 entry point for fetching json data from api and, transforming, storing and passing to
  subscription engine to process before sending.
  """
  @spec process_alerts() :: [{:ok, [Notification.t]}]
  def process_alerts() do
    with {:ok, alerts} <- AlertsClient.get_alerts(),
         {:ok, facility_map} <- ServiceInfoCache.get_facility_map() do
      {alerts_needing_notifications, alert_ids_to_clear_notifications} =
        {alerts, facility_map}
        |> parse_alerts()
        |> AlertCache.update_cache()

      SavedAlert.save!(alerts)
      HoldingQueue.remove_notifications(alert_ids_to_clear_notifications)
      SubscriptionFilterEngine.process_alerts(alerts_needing_notifications)
    end
  end

  defp parse_alerts({alerts, facilities_map}) do
    for alert_json <- alerts, alert = parse_alert(alert_json, facilities_map), into: %{} do
      {alert.id, alert}
    end
  end

  def parse_alert(%{
    "active_period" => active_periods,
    "effect_detail" => effect_name,
    "id" => alert_id,
    "informed_entity" => informed_entities,
    "service_effect_text" => service_effect_text_translations,
    "severity" => severity,
    "header_text" => header_text_translations
  } = alert_data, facilities_map) do
    %Alert{
      active_period: parse_active_periods(active_periods),
      description: alert_data |> Map.get("description_text") |> parse_translation(),
      effect_name: StringHelper.split_capitalize(effect_name, "_"),
      header: parse_translation(header_text_translations),
      id: to_string(alert_id),
      informed_entities: parse_informed_entities(informed_entities, facilities_map),
      last_push_notification: alert_data |> Map.get_lazy("last_push_notification_timestamp", fn -> Map.get(alert_data, "created_timestamp") end) |> parse_datetime(),
      service_effect: parse_translation(service_effect_text_translations),
      severity: parse_severity(severity),
      timeframe: parse_translation(alert_data["timeframe_text"]),
      recurrence: parse_translation(alert_data["recurrence_text"]),
    }
  end

  def parse_alert(alert, _) do
    Logger.warn("Failed to parse alert: #{Poison.encode!(alert)}")
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
    informed_entities
    |> Enum.map(fn(ie) ->
      struct_params = ie
        |> parse_informed_entity()
        |> set_route_for_amenity()

      Enum.map(struct_params, fn(sp) ->
        informed_entity = struct(InformedEntity, sp)
        with {:facility_id, facility_id} <- Enum.find(sp, &(elem(&1, 0) == :facility_id)),
             %{^facility_id => facility_type} <- facilities_map do
          %{informed_entity | facility_type: facility_type |> String.downcase() |> String.to_existing_atom()}
        else
          _ -> informed_entity
        end
      end)
    end)
    |> List.flatten()
  end

  defp parse_informed_entity(informed_entity) do
    Enum.reduce(informed_entity, %{}, fn({k, v}, acc) ->
      case k do
        "trip" ->
          Map.merge(acc, parse_trip(v, informed_entity))
        "stop_id" ->
          Map.merge(acc, parse_stop(v))
        "route_id" ->
          Map.put(acc, :route, v)
        "route_type" ->
          Map.put(acc, :route_type, v)
        "facility_id" ->
          Map.put(acc, :facility_id, v)
        "direction_id" ->
          Map.put(acc, :direction_id, v)
        "activities" ->
          Map.put(acc, :activities, v)
        _ ->
          acc
      end
    end)
  end

  defp set_route_for_amenity(%{facility_id: fid, stop: stop} = entity) when not is_nil(fid) do
    with {:ok, subway_infos} <- ServiceInfoCache.get_subway_info(),
      {:ok, cr_infos} <- ServiceInfoCache.get_commuter_rail_info(),
      routes <- get_routes_for_stop(stop, subway_infos ++ cr_infos) do
        Enum.map(routes, & Map.put(entity, :route, &1))
    else
      _ -> [entity]
    end
  end
  defp set_route_for_amenity(entity), do: [entity]

  defp get_routes_for_stop(stop, route_info) do
    route_info
    |> Enum.filter(&(List.keymember?(&1.stop_list, stop, 1)))
    |> Enum.map(&(&1.route_id))
  end

  defp parse_trip(%{"trip_id" => trip_id}, %{"route_type" => 4}) do
     case ServiceInfoCache.get_generalized_trip_id(trip_id) do
       {:ok, trip} -> %{trip: trip}
       _ -> %{}
     end
  end
  defp parse_trip(%{"trip_id" => trip_id}, _ie) do
    case ServiceInfoCache.get_trip_name(trip_id) do
      {:ok, trip_name} -> %{trip: trip_name}
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

  def parse_severity(sev) when sev >= 9, do: :extreme
  def parse_severity(sev) when sev >= 7, do: :severe
  def parse_severity(sev) when sev >= 5, do: :moderate
  def parse_severity(sev) when is_integer(sev), do: :minor

  def parse_translation(translations), do: do_parse_translation(translations)

  defp do_parse_translation(nil), do: nil
  defp do_parse_translation(translations) do
    case Enum.find(translations, &(&1["translation"]["language"] == "en")) do
      %{"translation" => %{"language" => "en", "text" => text}} -> text
      _ -> nil
    end
  end
end
