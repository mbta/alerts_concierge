defmodule AlertProcessor.DigestBuilder do
  @moduledoc """
  Generates digests for all users/alerts in the system
  """
  alias AlertProcessor.{InformedEntityFilter, Model, Repo}
  alias Model.{Alert, Digest, DigestDateGroup, Subscription}
  alias Calendar.DateTime, as: DT

  @doc """
  1. Takes a list of alerts
  2. Gets all users the alert affects
  3. Returns a list of Digest structs:
     [%Digest{user: user, alerts: [Alert]}]
  """
  @spec build_digests({[Alert.t], DigestDateGroup.t}, integer) :: [Digest.t]
  def build_digests({alerts, digest_date_group}, digest_interval) do
    subs =
      Subscription
      |> Repo.all()
      |> Repo.preload(:user)
      |> Repo.preload(:informed_entities)

    alerts
    |> Enum.map(fn(alert) ->
      {fetch_active_users(alert, subs, digest_interval), alert}
    end)
    |> sort_by_user(digest_date_group)
  end

  defp fetch_active_users(alert, subs, digest_interval) do
    {facility_subs, route_subs} = split_subscriptions_by_type(subs)

    next_digest_sent_at =
      DateTime.utc_now()
      |> DateTime.to_unix()
      |> Kernel.+(digest_interval)

    MapSet.new()
    |> subscribers_for_extreme_severity_alert(subs, alert: alert)
    |> subscribers_for_facility_alert(facility_subs, alert: alert)
    |> subscribers_for_whole_route(route_subs, alert: alert)
    |> subscribers_for_upcoming_entity_matches(subs, alert: alert)
    |> Enum.filter(fn user ->
      is_nil(user.vacation_end) or DateTime.to_unix(user.vacation_end) < next_digest_sent_at
    end)
  end

  defp split_subscriptions_by_type(subscriptions) do
    subscriptions
    |> Enum.split_with(fn(%{informed_entities: ies}) ->
      Enum.any?(ies, &(!is_nil(&1.facility_type)))
    end)
  end

  defp subscribers_for_extreme_severity_alert(users, subscriptions, alert: alert) do
    if alert.severity == :extreme do
      subscriptions
      |> Enum.map(&(&1.user))
      |> MapSet.new()
      |> MapSet.union(users)
    else
      users
    end
  end

  defp subscribers_for_facility_alert(users, subscriptions, alert: alert) do
    case Alert.facility_alert?(alert) do
      true ->
        InformedEntityFilter.filter(subscriptions, alert: alert)
        |> Enum.map(&(&1.user))
        |> MapSet.new()
        |> MapSet.union(users)
      false -> users
    end
  end

  defp subscribers_for_whole_route(users, subscriptions, alert: alert) do
    with false <- Alert.facility_alert?(alert),
      true <- Alert.severity_value(alert) >= 2 do
        subscriptions
        |> match_route_subs(alert: alert)
        |> Enum.map(&(&1.user))
        |> MapSet.new()
        |> MapSet.union(users)
    else
      _ -> users
    end
  end

  defp match_route_subs(subscriptions, alert: alert) do
    alert_routes =
      alert.informed_entities
      |> Enum.map(&(&1.route))
      |> Enum.uniq()

    Enum.filter(subscriptions, fn(sub) ->
      Enum.any?(sub.informed_entities, fn(ie) ->
        Enum.any?(alert_routes, &(&1 == ie.route))
      end)
    end)
  end

  defp subscribers_for_upcoming_entity_matches(users, subscriptions, alert: alert) do
    if minor_and_started?(alert) do
      users
    else
      subscriptions
      |> InformedEntityFilter.filter(alert: alert)
      |> Enum.map(&(&1.user))
      |> MapSet.new()
      |> MapSet.union(users)
    end
  end

  defp minor_and_started?(%Alert{severity: :minor, active_period: active_periods}) do
    now = DateTime.utc_now()
    Enum.any?(active_periods, fn(%{start: start, end: _}) ->
      DT.before?(start, now)
    end)
  end
  defp minor_and_started?(_), do: false

  defp sort_by_user(data, digest_date_group) do
    data
    |> Enum.reduce(%{}, fn({users, alert}, result) ->
      users
      |> Enum.reduce(result, fn(user, acc) ->
        Map.update(acc, user, [alert], &[alert | &1])
      end)
    end)
    |> Enum.map(fn({user, alerts}) ->
      %Digest{user: user, alerts: Enum.uniq(alerts), digest_date_group: digest_date_group}
    end)
  end
end
