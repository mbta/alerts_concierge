defmodule AlertProcessor.Subscription.Diagnostic do
  @moduledoc """
  Diagnosis of why a Notification was sent/not sent
  """

  alias AlertProcessor.{AlertParser, Model, ActivePeriodFilter,
    InformedEntityFilter, Helpers.StringHelper, Repo, SentAlertFilter,
    SeverityFilter, StructHelper, Subscription.Snapshot, NotificationBuilder}
  alias Model.{Alert, InformedEntity, SavedAlert, Notification}
  import Ecto.Query

  def diagnose_alert(user, %{"alert_date" => date_params, "alert_id" => alert_id}) do
    date = Enum.reduce(date_params, %{}, fn({k, v}, acc) ->
      Map.put(acc, k, String.to_integer(v))
    end)
    erl_param = {{date["year"], date["month"], date["day"]}, {date["hour"], date["minute"], 0}}

    with {:ok, datetime} <- Calendar.DateTime.from_erl(erl_param, "America/New_York"),
      notifications <- get_notifications(user.id, alert_id),
      {:ok, snapshots} <- Snapshot.get_snapshots_by_datetime(user, datetime),
      {:ok, alert} <- get_alert(alert_id),
      {:ok, alert_versions} <- get_alert_versions(alert, datetime),
      {:ok, alert_snapshot} <- serialize_alert_versions(alert_versions) do
        result = snapshots
        |> Enum.map(fn(snap) ->
          build_diagnosis(alert_snapshot, notifications, [snap])
        end)
        {:ok, result}
    else
      _ ->
        {:error, user}
    end
  end

  defp get_alert(alert_id) do
    case Repo.get_by(SavedAlert, alert_id: alert_id) do
      %SavedAlert{} = alert -> {:ok, alert}
      _ -> {:error, :no_alert}
    end
  end

  defp get_alert_versions(alert, datetime) do
    result =
      alert
      |> PaperTrail.get_versions()
      |> Enum.reject(fn(version) ->
        version_time = DateTime.from_naive!(version.inserted_at, "Etc/UTC")
        DateTime.compare(version_time, datetime) == :gt
      end)

    if result == [] do
      {:error, :no_versions}
    else
      {:ok, result}
    end
  end

  defp serialize_alert_versions(alert_versions) do
    snapshot =
      alert_versions
      |> Enum.reduce(%{}, fn(%{item_changes: changes}, acc) ->
        Map.merge(acc, changes["data"])
      end)
      |> serialize_alert()
      |> serialize_active_periods()
      |> serialize_informed_entities()

    {:ok, StructHelper.to_struct(Alert, snapshot)}
  end

  defp serialize_alert(alert) do
    Map.merge(alert, %{
      "effect_name" => StringHelper.split_capitalize(alert["effect_detail"], "_"),
      "header" => AlertParser.parse_translation(alert["header_text"]),
      "severity" => AlertParser.parse_severity(alert["severity"]),
      "last_push_notification" => DateTime.from_unix!(alert["last_push_notification_timestamp"]),
      "service_effect" => AlertParser.parse_translation(alert["service_effect_text"]),
      "description" => AlertParser.parse_translation(alert["description_text"]),
      "timeframe" => AlertParser.parse_translation(alert["timeframe_text"]),
      "recurrence" => AlertParser.parse_translation(alert["recurrence_text"])
    })
  end

  defp serialize_active_periods(alert) do
    active_periods = Enum.map(alert["active_period"], fn(ap) ->
      serialize_active_period(ap)
    end)
    Map.put(alert, "active_period", active_periods)
  end

  def serialize_active_period(map) do
    for {key, val} <- map, into: %{} do
       {String.to_existing_atom(key), DateTime.from_unix!(val)}
    end
  end

  defp serialize_informed_entities(alert) do
    informed_entities = Enum.map(alert["informed_entity"], fn(ie) ->
      StructHelper.to_struct(InformedEntity, ie)
    end)
    Map.put(alert, "informed_entities", informed_entities)
  end

  defp get_notifications(user_id, alert_id) do
    notification_query = from n in Notification,
      where: n.user_id == ^user_id,
      where: n.alert_id == ^alert_id,
      select: n

    Repo.all(notification_query)
  end

  defp build_diagnosis(alert, notifications, [sub | _] = subscriptions) do
    %{
      alert: alert,
      subscription: sub
    }
    |> alert_sent?(alert: alert, subscriptions: subscriptions, notifications: notifications)
    |> matches_informed_entities?(alert: alert, subscriptions: subscriptions)
    |> matches_severity?(alert: alert, subscriptions: subscriptions)
    |> matches_active_period?(alert: alert, subscriptions: subscriptions)
    |> matches_vacation_period?(alert: alert, user: sub.user)
    |> matches_dnd_period?(alert: alert, user: sub.user)
  end

  defp alert_sent?(diagnostic, alert: alert, subscriptions: subscriptions, notifications: notifications) do
    subs = SentAlertFilter.filter(subscriptions, alert: alert, notifications: notifications)

    if length(subs) > 0 do
      Map.put(diagnostic, :passed_sent_alert_filter?, true)
    else
      Map.put(diagnostic, :passed_sent_alert_filter?, false)
    end
  end

  defp matches_active_period?(diagnostic, alert: alert, subscriptions: subscriptions) do
    subs = ActivePeriodFilter.filter(subscriptions, alert: alert)

    if length(subs) > 0 do
      Map.put(diagnostic, :passed_active_period_filter?, true)
    else
      Map.put(diagnostic, :passed_active_period_filter?, false)
    end
  end

  defp matches_informed_entities?(diagnostic, alert: alert, subscriptions: subscriptions) do
    subs = InformedEntityFilter.filter(subscriptions, alert: alert)

    if length(subs) > 0 do
      Map.put(diagnostic, :passed_informed_entity_filter?, true)
    else
      diagnostic
      |> Map.put(:passed_informed_entity_filter?, false)
      |> match_informed_entities(alert: alert)
    end
  end

  defp matches_severity?(diagnostic, alert: alert, subscriptions: subscriptions) do
    subs = SeverityFilter.filter(subscriptions, alert: alert)

    if length(subs) > 0 do
      Map.put(diagnostic, :passed_severity_filter?, true)
    else
      Map.put(diagnostic, :passed_severity_filter?, false)
    end
  end

  def match_informed_entities(%{subscription: %{informed_entities: ies}} = diagnostic, alert: alert) do
    diagnostic
    |> matches_any_direction?(alert: alert, informed_entities: ies)
    |> matches_any_facility?(alert: alert, informed_entities: ies)
    |> matches_any_route?(alert: alert, informed_entities: ies)
    |> matches_any_route_type?(alert: alert, informed_entities: ies)
    |> matches_any_stop?(alert: alert, informed_entities: ies)
    |> matches_any_trip?(alert: alert, informed_entities: ies)
  end

  defp matches_any_direction?(diagnostic, alert: alert, informed_entities: ies) do
    alert_ies_directions = Enum.map(alert.informed_entities, &(&1.direction_id))
    ies_directions = Enum.map(ies, &(&1.direction_id))

    if length(alert_ies_directions -- ies_directions) > length(alert_ies_directions) do
      Map.put(diagnostic, :matches_any_direction?, true)
    else
      Map.put(diagnostic, :matches_any_direction?, false)
    end
  end

  defp matches_any_facility?(diagnostic, alert: alert, informed_entities: ies) do
    alert_ies_facilities = Enum.map(alert.informed_entities, &(&1.facility_type))
    ies_facilities = Enum.map(ies, &(&1.facility_type))

    if length(alert_ies_facilities -- ies_facilities) > length(alert_ies_facilities) do
      Map.put(diagnostic, :matches_any_facility?, true)
    else
      Map.put(diagnostic, :matches_any_facility?, false)
    end
  end

  defp matches_any_route?(diagnostic, alert: alert, informed_entities: ies) do
    alert_ies_routes = Enum.map(alert.informed_entities, &(&1.route))
    ies_routes = Enum.map(ies, &(&1.route))

    if length(alert_ies_routes -- ies_routes) > length(alert_ies_routes) do
      Map.put(diagnostic, :matches_any_route?, true)
    else
      Map.put(diagnostic, :matches_any_route?, false)
    end
  end

  defp matches_any_route_type?(diagnostic, alert: alert, informed_entities: ies) do
    alert_ies_route_types = Enum.map(alert.informed_entities, &(&1.route_type))
    ies_route_types = Enum.map(ies, &(&1.route_type))

    if length(alert_ies_route_types -- ies_route_types) > length(alert_ies_route_types) do
      Map.put(diagnostic, :matches_any_route_type?, true)
    else
      Map.put(diagnostic, :matches_any_route_type?, false)
    end
  end

  defp matches_any_stop?(diagnostic, alert: alert, informed_entities: ies) do
    alert_ies_stops = Enum.map(alert.informed_entities, &(&1.stop))
    ies_stops = Enum.map(ies, &(&1.stop))

    if length(alert_ies_stops -- ies_stops) > length(alert_ies_stops) do
      Map.put(diagnostic, :matches_any_stop?, true)
    else
      Map.put(diagnostic, :matches_any_stop?, false)
    end
  end

  defp matches_any_trip?(diagnostic, alert: alert, informed_entities: ies) do
    alert_ies_trips = Enum.map(alert.informed_entities, &(&1.trip))
    ies_trips = Enum.map(ies, &(&1.trip))

    if length(alert_ies_trips -- ies_trips) > length(alert_ies_trips) do
      Map.put(diagnostic, :matches_any_trip?, true)
    else
      Map.put(diagnostic, :matches_any_trip?, false)
    end
  end

  defp matches_vacation_period?(diagnostic, alert: alert, user: user) do
    user =
      user
      |> Map.put(:do_not_disturb_start, nil)
      |> Map.put(:do_not_disturb_end, nil)

    result = Enum.any?(alert.active_period, fn(ap) ->
      end_time = Map.get(ap, :end, nil)
      case NotificationBuilder.calculate_send_after(user, {ap.start, end_time}, alert.last_push_notification) do
        %DateTime{} -> true
        _ -> false
      end
    end)

    if result do
      Map.put(diagnostic, :passes_vacation_period?, true)
    else
      Map.put(diagnostic, :passes_vacation_period?, false)
    end
  end

  defp matches_dnd_period?(diagnostic, alert: alert, user: user) do
    user =
      user
      |> Map.put(:vacation_start, nil)
      |> Map.put(:vacation_end, nil)

    result = Enum.any?(alert.active_period, fn(ap) ->
      end_time = Map.get(ap, :end, nil)
      case NotificationBuilder.calculate_send_after(user, {ap.start, end_time}, alert.last_push_notification) do
        %DateTime{} -> true
        _ -> false
      end
    end)

    if result do
      Map.put(diagnostic, :passes_do_not_disturb?, true)
    else
      Map.put(diagnostic, :passes_do_not_disturb?, false)
    end
  end
end
