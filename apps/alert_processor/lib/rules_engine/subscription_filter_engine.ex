defmodule AlertProcessor.SubscriptionFilterEngine do
  @moduledoc """
  Entry point for susbcription engine to filter users to alert users
  with relevant subscriptions to alert provided.
  """
  alias AlertProcessor.{
    ActivePeriodFilter,
    InformedEntityFilter,
    Model,
    Scheduler,
    SentAlertFilter
  }

  alias Model.{Alert, Notification, Subscription}
  require Logger

  @notification_window_filter Application.get_env(:alert_processor, :notification_window_filter)

  @doc """
  Determine distinct notifications and schedule them to be sent.

  We are intentionally not collecting the notifications that go out as our consumers don't need them and it is a performance hit.
  """
  @spec schedule_all_notifications([Alert.t()], atom | nil) :: any
  def schedule_all_notifications(alerts, alert_filter_duration_type \\ :anytime) do
    start_time = Time.utc_now()
    active_subscriptions = Subscription.all_active_for_alerts(alerts)
    recent_notifications = Notification.most_recent_for_subscriptions_and_alerts(alerts)
    schedule_notifications(active_subscriptions, recent_notifications, alerts)

    Logger.info(fn ->
      time = Time.diff(Time.utc_now(), start_time, :millisecond)
      alert_type = if time > 0, do: "alert matching", else: "alert matching (bad time)"
      "#{alert_type} #{alert_filter_duration_type}, time=#{time} alert_count=#{length(alerts)}"
    end)

    :ok
  end

  defp schedule_notifications(subscriptions, recent_notifications, alerts)
       when is_list(alerts) do
    options = [ordered: false, timeout: 600_000]

    alerts
    |> Task.async_stream(
      &schedule_notifications(subscriptions, recent_notifications, &1),
      options
    )
    |> Stream.run()
  end

  defp schedule_notifications(subscriptions, recent_notifications, %Alert{} = alert) do
    matched_subscriptions = determine_recipients(alert, subscriptions, recent_notifications)
    schedule_distinct_notifications(alert, matched_subscriptions)
  end

  @doc """
  determine_recipients/3 receives an alert and applies relevant filters to exclude users who should not be notified
  """
  @spec determine_recipients(Alert.t(), [Subscription.t()], [Notification.t()], DateTime.t()) :: [
          Subscription.t()
        ]
  def determine_recipients(
        alert,
        subscriptions,
        notifications,
        now \\ Calendar.DateTime.now!("America/New_York")
      ) do
    {subscriptions_to_test, subscriptions_to_auto_resend} =
      SentAlertFilter.filter(subscriptions, alert, notifications, now)

    subscriptions_to_test
    |> @notification_window_filter.filter(now)
    |> InformedEntityFilter.filter(alert: alert)
    |> ActivePeriodFilter.filter(alert: alert)
    |> Kernel.++(subscriptions_to_auto_resend)
  end

  @spec schedule_distinct_notifications(Alert.t(), [Subscription.t()]) ::
          {:ok, [Notification.t()]} | :error
  def schedule_distinct_notifications(alert, subscriptions) do
    subscriptions
    |> Enum.group_by(& &1.user)
    |> Map.to_list()
    |> Scheduler.schedule_notifications(alert)
  end
end
