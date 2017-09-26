defmodule AlertProcessor.Subscription.Diagnostic do
  @moduledoc """
  Diagnosis of why a Notification was sent/not sent
  """

  alias AlertProcessor.{ActivePeriodFilter,
    InformedEntityFilter, SentAlertFilter,
    SeverityFilter, Subscription, NotificationBuilder}
  alias Subscription.{DiagnosticQuery, Snapshot}

  @diagnostic_checks [
    :passed_sent_alert_filter?,
    :passed_informed_entity_filter?,
    :passed_severity_filter?,
    :passed_active_period_filter?,
    :passes_vacation_period?,
    :passes_do_not_disturb?
  ]

  def sort(diagnoses) do
    {succeeded, failed} = Enum.split_with(diagnoses, fn(diag) ->
      diag
      |> Map.take(@diagnostic_checks)
      |> Map.values()
      |> Enum.all?
    end)

   %{
      succeeded: succeeded,
      failed: failed,
      all: diagnoses || []
    }
  end

  def diagnose_alert(user, %{"alert_date" => date_params, "alert_id" => alert_id}) do
    date = Enum.reduce(date_params, %{}, fn({k, v}, acc) ->
      Map.put(acc, k, String.to_integer(v))
    end)
    erl_param = {{date["year"], date["month"], date["day"]}, {date["hour"], date["minute"], 0}}

    with {:ok, datetime} <- Calendar.DateTime.from_erl(erl_param, "America/New_York"),
      notifications <- DiagnosticQuery.get_notifications(user.id, alert_id),
      {:ok, snapshots} <- Snapshot.get_snapshots_by_datetime(user, datetime),
      {:ok, alert} <- DiagnosticQuery.get_alert(alert_id),
      {:ok, alert_versions} <- DiagnosticQuery.get_alert_versions(alert, datetime),
      {:ok, alert_snapshot} <- Snapshot.serialize_alert_versions(alert_versions) do
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
    result = SentAlertFilter.filter(subscriptions, alert: alert, notifications: notifications) != {[], []}
    Map.put(diagnostic, :passed_sent_alert_filter?, result)
  end

  defp matches_active_period?(diagnostic, alert: alert, subscriptions: subscriptions) do
    result = ActivePeriodFilter.filter(subscriptions, alert: alert) != []
    Map.put(diagnostic, :passed_active_period_filter?, result)
  end

  defp matches_informed_entities?(diagnostic, alert: alert, subscriptions: subscriptions) do
    subs = InformedEntityFilter.filter(subscriptions, alert: alert)

    if subs == [] do
      diagnostic
      |> Map.put(:passed_informed_entity_filter?, false)
      |> match_informed_entities(alert: alert)
    else
      Map.put(diagnostic, :passed_informed_entity_filter?, true)
    end
  end

  defp matches_severity?(diagnostic, alert: alert, subscriptions: subscriptions) do
    result = SeverityFilter.filter(subscriptions, alert: alert) != []
    Map.put(diagnostic, :passed_severity_filter?, result)
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
    result = length(alert_ies_directions -- ies_directions) > length(alert_ies_directions)
    Map.put(diagnostic, :matches_any_direction?, result)
  end

  defp matches_any_facility?(diagnostic, alert: alert, informed_entities: ies) do
    alert_ies_facilities = Enum.map(alert.informed_entities, &(&1.facility_type))
    ies_facilities = Enum.map(ies, &(&1.facility_type))
    result = length(alert_ies_facilities -- ies_facilities) > length(alert_ies_facilities)
    Map.put(diagnostic, :matches_any_facility?, result)
  end

  defp matches_any_route?(diagnostic, alert: alert, informed_entities: ies) do
    alert_ies_routes = Enum.map(alert.informed_entities, &(&1.route))
    ies_routes = Enum.map(ies, &(&1.route))
    result = length(alert_ies_routes -- ies_routes) > length(alert_ies_routes)
    Map.put(diagnostic, :matches_any_route?, result)
  end

  defp matches_any_route_type?(diagnostic, alert: alert, informed_entities: ies) do
    alert_ies_route_types = Enum.map(alert.informed_entities, &(&1.route_type))
    ies_route_types = Enum.map(ies, &(&1.route_type))
    result = length(alert_ies_route_types -- ies_route_types) > length(alert_ies_route_types)
    Map.put(diagnostic, :matches_any_route_type?, result)
  end

  defp matches_any_stop?(diagnostic, alert: alert, informed_entities: ies) do
    alert_ies_stops = Enum.map(alert.informed_entities, &(&1.stop))
    ies_stops = Enum.map(ies, &(&1.stop))
    result = length(alert_ies_stops -- ies_stops) > length(alert_ies_stops)
    Map.put(diagnostic, :matches_any_stop?, result)
  end

  defp matches_any_trip?(diagnostic, alert: alert, informed_entities: ies) do
    alert_ies_trips = Enum.map(alert.informed_entities, &(&1.trip))
    ies_trips = Enum.map(ies, &(&1.trip))
    result = length(alert_ies_trips -- ies_trips) > length(alert_ies_trips)
    Map.put(diagnostic, :matches_any_trip?, result)
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

    Map.put(diagnostic, :passes_vacation_period?, result)
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

    Map.put(diagnostic, :passes_do_not_disturb?, result)
  end
end
