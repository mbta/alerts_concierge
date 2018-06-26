defmodule AlertProcessor.SubscriptionFilterEngine do
  @moduledoc """
  Entry point for susbcription engine to filter users to alert users
  with relevant subscriptions to alert provided.
  """
  alias AlertProcessor.{ActivePeriodFilter, InformedEntityFilter, Model,
    Repo, Scheduler, SentAlertFilter}
  alias Model.{Alert, Notification, Subscription}
  require Logger

  @notification_window_filter Application.get_env(:alert_processor, :notification_window_filter)

  @spec schedule_all_notifications([Alert.t]) :: any
  def schedule_all_notifications(alerts) do
    start_time = Time.utc_now()
    all_subscriptions = Subscription |> Repo.all() |> Repo.preload(:user)
    recent_notifications = Notification.most_recent_for_subscriptions_and_alerts(alerts)
    scheduled_notifications = schedule_notifications(all_subscriptions, recent_notifications, alerts)
    Logger.info(fn ->
      "alert matching, time=#{Time.diff(Time.utc_now(), start_time, :millisecond)}"
    end)
    scheduled_notifications
  end

  defp schedule_notifications(all_subscriptions, recent_notifications, alerts) when is_list(alerts) do
    options = [ordered: false, timeout: 600_000]
    notifications =
      alerts
      |> Task.async_stream(&(schedule_notifications(all_subscriptions, recent_notifications, &1)), options)
      |> Enum.map(fn {:ok, notification} -> notification end)
    {:ok, notifications}
  end

  defp schedule_notifications(all_subscriptions, recent_notifications, %Alert{} = alert) do
    matched_subscriptions = determine_recipients(alert, all_subscriptions, recent_notifications)
    schedule_distinct_notifications(alert, matched_subscriptions)
  end

  @doc """
  determine_recipients/3 receives an alert and applies relevant filters to exclude users who should not be notified
  """
  @spec determine_recipients(Alert.t, [Subscription.t], [Notification.t], DateTime.t) :: [Subscription.t]
  def determine_recipients(alert, subscriptions, notifications, now \\ Calendar.DateTime.now!("America/New_York")) do
    {subscriptions_to_test, subscriptions_to_auto_resend} =
      SentAlertFilter.filter(subscriptions, alert, notifications, now)

    subscriptions_to_test
    |> @notification_window_filter.filter(now)
    |> InformedEntityFilter.filter(alert: alert)
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
end
