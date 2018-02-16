defmodule AlertProcessor.SubscriptionFilterEngine do
  @moduledoc """
  Entry point for susbcription engine to filter users to alert users
  with relevant subscriptions to alert provided.
  """
  alias AlertProcessor.{ActivePeriodFilter, InformedEntityFilter, Model,
    Repo, Scheduler, SentAlertFilter, SeverityFilter}
  alias Model.{Alert, Notification, Subscription}
  require Logger

  @spec schedule_all_notifications([Alert.t]) :: {integer, Keyword.t}
  def schedule_all_notifications(alerts) do
    all_subscriptions = Subscription
    |> Repo.all()
    |> Repo.preload(:user)
    |> Repo.preload(:informed_entities)

    subscription_timestamp = Subscription.get_last_inserted_timestamp()
    start_time = Time.utc_now()

    {skipped, matched_notifications} = Enum.reduce(alerts, {0, []}, fn(alert, {last_skipped, existing_notifications}) ->
      {checked?, old_timestamp} = get_and_set_last_subscription_timestamp(alert, subscription_timestamp)
      new_subscriptions = subscritptions_new_to_alert(checked?, all_subscriptions, subscription_timestamp, old_timestamp)
      case new_subscriptions do
        [] -> {last_skipped + 1, [{:ok, []}] ++ existing_notifications}
        new_subscriptions ->
          notifications = Notification.most_recent_for_subscriptions_and_alerts(new_subscriptions, [alert])
          matched_subscriptions = determine_recipients(alert, new_subscriptions, notifications)
          notifications = schedule_distinct_notifications(alert, matched_subscriptions)
          {last_skipped, [notifications] ++ existing_notifications}
      end
    end)
    Logger.info(fn -> "alert matching, time=#{Time.diff(Time.utc_now(), start_time, :millisecond)}, skipped: #{skipped}" end)
    {skipped, matched_notifications}
  end

  @doc """
  determine_recipients/3 receives an alert and applies relevant filters to exclude users who should not be notified
  """
  @spec determine_recipients(Alert.t, [Subscription.t], [Notification.t]) :: [Subscription.t]
  def determine_recipients(alert, subscriptions, notifications) do
    {subscriptions_to_test, subscriptions_to_auto_resend} = SentAlertFilter.filter(subscriptions,
                                                                                   alert: alert,
                                                                                   notifications: notifications)
    subscriptions_to_test
    |> InformedEntityFilter.filter(alert: alert)
    |> SeverityFilter.filter(alert: alert)
    |> ActivePeriodFilter.filter(alert: alert)
    |> Kernel.++(subscriptions_to_auto_resend)
  end

  @spec schedule_distinct_notifications(Alert.t, [Subscription.t]) :: {:ok, [Notification.t]} | :error
  def schedule_distinct_notifications(alert, subscriptions) do
    subscriptions
    |> Enum.group_by(& &1.user)
    |> Map.to_list()
    |> Scheduler.schedule_notifications(alert)
  end

  defp get_and_set_last_subscription_timestamp(alert, new_timestamp) do
    name = :subscription_filter
    key = :erlang.phash2(alert)
    case ConCache.get(name, key) do
      nil ->
        cache_alert(name, key, new_timestamp)
        {false, nil}
      old_timestamp ->
        if old_timestamp != new_timestamp, do: cache_alert(name, key, new_timestamp)
        {true, old_timestamp}
    end
  end

  defp cache_alert(name, key, value) do
    ConCache.put(name, key, %ConCache.Item{value: value, ttl: :timer.hours(12)})
  end

  defp subscritptions_new_to_alert(true, _subscriptions, last_timestamp, last_timestamp), do: []
  defp subscritptions_new_to_alert(false, subscriptions, _, _), do: subscriptions
  defp subscritptions_new_to_alert(true, subscriptions, _last_timestamp, cached_timestamp) do
    Enum.filter(subscriptions, & &1.inserted_at > cached_timestamp)
  end
end
