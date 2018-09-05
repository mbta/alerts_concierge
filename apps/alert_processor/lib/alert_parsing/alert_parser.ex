defmodule AlertProcessor.AlertParser do
  @moduledoc """
  Module used to parse alerts from api and transform into Alert structs and pass along
  relevant information to subscription filter engine.
  """
  require Logger

  alias AlertProcessor.{
    AlertCourtesyEmail,
    AlertFilters,
    AlertsClient,
    ApiClient,
    CachedApiClient,
    Parser,
    ServiceInfoCache,
    SubscriptionFilterEngine,
    Memory,
    Reminders
  }

  alias AlertProcessor.Helpers.{DateTimeHelper, StringHelper}

  alias AlertProcessor.Model.{Alert, InformedEntity, Notification, SavedAlert}

  @behaviour Parser

  @doc """
  process_alerts/1 entry point for fetching json data from api and, transforming, storing and passing to
  subscription engine to process before sending.
  """
  @spec process_alerts(atom | nil) :: [{:ok, [Notification.t()]}]
  def process_alerts(alert_filter_duration_type \\ :anytime) do
    with {:ok, alerts, feed_timestamp} <- AlertsClient.get_alerts(),
         {:ok, api_alerts, _} <- ApiClient.get_alerts(),
         {:ok, facility_map} <- ServiceInfoCache.get_facility_map() do
      updated_alerts = swap_informed_entities(alerts, api_alerts)

      saved_alerts =
        updated_alerts
        |> SavedAlert.save!()
        |> Enum.filter(&(&1 != nil))

      parsed_alerts = parse_alerts({updated_alerts, facility_map, feed_timestamp})

      alerts_needing_notifications =
        AlertFilters.filter_by_duration_type(parsed_alerts, alert_filter_duration_type)

      Logger.info(fn ->
        "alert filter, duration_type=#{alert_filter_duration_type} alert_count=#{
          length(alerts_needing_notifications)
        }"
      end)

      if alert_filter_duration_type == :older do
        Reminders.async_schedule_reminders(alerts_needing_notifications)
      end

      memory_before = Memory.now()

      SubscriptionFilterEngine.schedule_all_notifications(
        alerts_needing_notifications,
        alert_filter_duration_type
      )

      Logger.info(fn ->
        mem_string =
          Memory.now()
          |> Memory.diff(memory_before)
          |> Memory.to_string()

        "Memory change due to scheduling notifications: #{mem_string}"
      end)

      AlertCourtesyEmail.send_courtesy_emails(saved_alerts, parsed_alerts)

      {alerts, api_alerts, updated_alerts}
    end
  end

  @doc false
  def parse_alerts({alerts, facilities_map, feed_timestamp}) do
    start_time = Time.utc_now()

    parsed_alerts =
      for alert_json <- remove_ignored(alerts) do
        parse_alert(alert_json, facilities_map, feed_timestamp)
      end

    Logger.info(fn ->
      "alert parsing, time=#{Time.diff(Time.utc_now(), start_time, :millisecond)} alert_count=#{
        length(alerts)
      }"
    end)

    parsed_alerts
  end

  @spec remove_ignored([map]) :: [map]
  def remove_ignored(alerts) do
    alerts
    |> filter_invalid_key_value("last_push_notification_timestamp")
    |> filter_invalid_key_value("informed_entity")
  end

  @spec filter_invalid_key_value([map], String.t()) :: [map]
  defp filter_invalid_key_value(alerts, key) do
    filter_fun = fn
      %{^key => ""} -> false
      %{^key => nil} -> false
      %{^key => []} -> false
      %{^key => _} -> true
      _ -> false
    end

    alerts
    |> Enum.filter(filter_fun)
  end

  def parse_alert(
        %{
          "id" => id,
          "created_timestamp" => created_timestamp,
          "duration_certainty" => duration_certainty,
          "effect_detail" => effect_detail,
          "header_text" => header_text,
          "informed_entity" => informed_entity,
          "service_effect_text" => service_effect_text,
          "severity" => severity,
          "last_push_notification_timestamp" => last_push_notification_timestamp
        } = alert_data,
        facilities_map,
        feed_timestamp
      ) do
    active_period = Map.get(alert_data, "active_period")

    %Alert{}
    |> parse_duration_certainty(duration_certainty, active_period, feed_timestamp)
    |> parse_active_periods(active_period, created_timestamp)
    |> parse_informed_entities(informed_entity, facilities_map)
    |> Map.put(:created_at, parse_datetime(created_timestamp))
    |> Map.put(:description, parse_translation(alert_data["description_text"]))
    |> Map.put(:url, parse_translation(alert_data["url"]))
    |> Map.put(:effect_name, StringHelper.split_capitalize(effect_detail, "_"))
    |> Map.put(:header, parse_translation(header_text))
    |> Map.put(:id, to_string(id))
    |> Map.put(:service_effect, parse_translation(service_effect_text))
    |> Map.put(:last_push_notification, parse_datetime(last_push_notification_timestamp))
    |> Map.put(:severity, parse_severity(severity))
    |> Map.put(:timeframe, parse_translation(alert_data["timeframe_text"]))
    |> Map.put(:recurrence, parse_translation(alert_data["recurrence_text"]))
    |> Map.put(:closed_timestamp, parse_datetime_or_nil(alert_data["closed_timestamp"]))
    |> Map.put(:reminder_times, parse_reminder_times(alert_data["reminder_times"]))
  end

  def parse_alert(alert, _, _) do
    Logger.warn("Failed to parse alert: #{Poison.encode!(alert)}")
    nil
  end

  defp parse_datetime(datetime) do
    {:ok, dt} = DateTime.from_unix(datetime)
    dt
  end

  defp parse_datetime_or_nil(nil), do: nil
  defp parse_datetime_or_nil(datetime), do: parse_datetime(datetime)

  defp parse_duration_certainty(alert, _, nil, _), do: alert

  defp parse_duration_certainty(
         alert,
         "ESTIMATED",
         [%{"start" => _start_timestamp, "end" => end_timestamp}],
         feed_timestamp
       ) do
    estimated_duration = round((end_timestamp - feed_timestamp) / 900) * 900
    %{alert | duration_certainty: {:estimated, estimated_duration}}
  end

  defp parse_duration_certainty(alert, _, _, _), do: %{alert | duration_certainty: :known}

  defp parse_active_periods(alert, nil, _), do: alert

  defp parse_active_periods(
         %Alert{duration_certainty: {:estimated, _}} = alert,
         [%{"start" => start_timestamp, "end" => _end_timestamp}],
         created_timestamp
       ) do
    {:ok, start_datetime} = DateTimeHelper.parse_unix_timestamp(start_timestamp)
    {:ok, end_datetime} = DateTimeHelper.parse_unix_timestamp(created_timestamp + 36 * 60 * 60)

    %{alert | active_period: [%{start: start_datetime, end: end_datetime}]}
  end

  defp parse_active_periods(alert, active_periods, _) do
    %{alert | active_period: Enum.map(active_periods, &parse_active_period(&1))}
  end

  defp parse_active_period(active_period) do
    active_period
    |> Map.new(fn {k, v} ->
      with {:ok, datetime} <- DateTimeHelper.parse_unix_timestamp(v) do
        {String.to_existing_atom(k), datetime}
      else
        _ -> {String.to_existing_atom(k), nil}
      end
    end)
    |> Map.put_new(:end, nil)
  end

  defp parse_informed_entities(alert, informed_entities, facilities_map) do
    informed_entities =
      Enum.flat_map(informed_entities, fn ie ->
        struct_params =
          ie
          |> parse_informed_entity()
          |> remove_stops_for_bus()
          |> Enum.flat_map(&set_route_for_amenity/1)

        Enum.map(struct_params, fn sp ->
          informed_entity = struct(InformedEntity, sp)

          with {:facility_id, facility_id} <- Enum.find(sp, &(elem(&1, 0) == :facility_id)),
               %{^facility_id => facility_type} <- facilities_map do
            %{
              informed_entity
              | facility_type: facility_type |> String.downcase() |> String.to_existing_atom()
            }
          else
            _ -> informed_entity
          end
        end)
      end)

    %{alert | informed_entities: informed_entities}
  end

  defp parse_informed_entity(informed_entity) do
    Enum.reduce(informed_entity, %{}, fn {k, v}, acc ->
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

  defp remove_stops_for_bus(%{route_type: 3} = entity), do: [entity, Map.put(entity, :stop, nil)]
  defp remove_stops_for_bus(entity), do: [entity]

  defp set_route_for_amenity(%{facility_id: fid, stop: stop} = entity) when not is_nil(fid) do
    with {:ok, subway_infos} <- ServiceInfoCache.get_subway_info(),
         {:ok, cr_infos} <- ServiceInfoCache.get_commuter_rail_info(),
         {:ok, bus_infos} <- ServiceInfoCache.get_bus_info(),
         routes <- get_routes_for_stop(stop, subway_infos ++ cr_infos ++ bus_infos) do
      Enum.map(routes, &Map.put(entity, :route, &1))
    else
      _ -> [entity]
    end
  end

  defp set_route_for_amenity(entity), do: [entity]

  defp get_routes_for_stop(stop, route_info) do
    route_info
    |> Enum.filter(&List.keymember?(&1.stop_list, stop, 1))
    |> Enum.map(& &1.route_id)
  end

  defp parse_trip(trip, informed_entity) do
    %{
      trip: get_trip_name(trip, informed_entity),
      schedule: get_schedule(trip, informed_entity)
    }
  end

  defp get_trip_name(%{"trip_id" => trip_id}, %{"route_type" => 4}) do
    case ServiceInfoCache.get_generalized_trip_id(trip_id) do
      {:ok, trip_name} -> trip_name
      _ -> nil
    end
  end

  defp get_trip_name(%{"trip_id" => trip_id}, _informed_enttiy) do
    case ServiceInfoCache.get_trip_name(trip_id) do
      {:ok, trip_name} -> trip_name
      _ -> nil
    end
  end

  defp get_schedule(%{"trip_id" => trip_id} = trip, %{"route_type" => route_type})
       when route_type in [2, 4] do
    with nil <- Map.get(trip, "stop_id"),
         {:ok, schedule} <- CachedApiClient.schedule_for_trip(trip_id) do
      Enum.map(schedule, &parse_schedule_event/1)
    else
      _ -> nil
    end
  end

  defp get_schedule(_, _), do: nil

  defp parse_schedule_event(event) do
    %{
      departure_time: event["attributes"]["departure_time"],
      stop_id: stop_from_schedule_event(event),
      trip_id: event["relationships"]["trip"]["data"]["id"]
    }
  end

  defp stop_from_schedule_event(event) do
    stop_id = event["relationships"]["stop"]["data"]["id"]
    ensure_parent_stop_id(stop_id)
  end

  defp parse_stop(stop_id) do
    %{stop: ensure_parent_stop_id(stop_id)}
  end

  defp ensure_parent_stop_id(stop_id) do
    case ServiceInfoCache.get_parent_stop_id(stop_id) do
      {:ok, parent_stop_id} when is_binary(parent_stop_id) -> parent_stop_id
      _ -> stop_id
    end
  end

  def parse_severity(sev) when sev >= 9, do: :extreme
  def parse_severity(sev) when sev >= 7, do: :severe
  def parse_severity(sev) when sev >= 5, do: :moderate
  def parse_severity(sev) when is_integer(sev), do: :minor

  @doc """
  Parses a `TranslatedString` type per the GTFS-realtime specification. For
  more details please see:
  https://developers.google.com/transit/gtfs-realtime/reference/#message_translatedstring

  Note that it also accepts a list of translations, which is not a correct
  `TranslatedString` type, but we need to support it since that's how the feed
  we're working with works.

  """
  @spec parse_translation(map | list) :: String.t() | nil
  def parse_translation(translations), do: do_parse_translation(translations)

  defp do_parse_translation(nil), do: nil

  defp do_parse_translation(%{"translation" => translations}) do
    case Enum.find(translations, &(&1["language"] == "en")) do
      %{"text" => text} -> text
      _ -> nil
    end
  end

  defp do_parse_translation(translations) when is_list(translations) do
    case Enum.find(translations, &(&1["translation"]["language"] == "en")) do
      %{"translation" => %{"language" => "en", "text" => text}} -> text
      _ -> nil
    end
  end

  defp parse_reminder_times(reminder_times) when is_list(reminder_times) do
    Enum.map(reminder_times, &parse_datetime(&1))
  end

  defp parse_reminder_times(_), do: []

  @doc """
  Some trips run on multiple routes. Currently the API adds these additional routes
  to the list of the informed entities, but the IBI feed does not. Rather than re-do
  that work in this project we replace the informed entities from the feed with the
  informed entities from the API
  """
  def swap_informed_entities(alerts, api_alerts) do
    api_alerts_by_id =
      Enum.reduce(api_alerts, %{}, fn alert, accumulator ->
        Map.put(accumulator, alert["id"], alert)
      end)

    Enum.reduce(alerts, [], fn alert, accumulator ->
      if Map.has_key?(api_alerts_by_id, alert["id"]) do
        accumulator ++
          [
            Map.put(
              alert,
              "informed_entity",
              translate_api_informed_entities(
                api_alerts_by_id[alert["id"]]["attributes"]["informed_entity"]
              )
            )
          ]
      else
        accumulator
      end
    end)
  end

  defp translate_api_informed_entities(api_entities) do
    Enum.map(api_entities, fn entity ->
      entity
      |> Enum.map(&translate_api_informed_entity_key(&1, entity))
      |> Enum.into(%{})
    end)
  end

  defp translate_api_informed_entity_key({"route", value}, _), do: {"route_id", value}
  defp translate_api_informed_entity_key({"stop", value}, _), do: {"stop_id", value}
  defp translate_api_informed_entity_key({"route_type", value}, _), do: {"route_type", value}
  defp translate_api_informed_entity_key({"direction_id", value}, _), do: {"direction_id", value}
  defp translate_api_informed_entity_key({"activities", value}, _), do: {"activities", value}
  defp translate_api_informed_entity_key({"facility", value}, _), do: {"facility", value}

  defp translate_api_informed_entity_key({"trip", value}, informed_entity) do
    {"trip", %{"route_id" => Map.get(informed_entity, "route"), "trip_id" => value}}
  end
end
