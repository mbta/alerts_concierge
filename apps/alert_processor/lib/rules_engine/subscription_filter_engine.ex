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
    schedule_notifications(alerts)

    Logger.info(fn ->
      time = Time.diff(Time.utc_now(), start_time, :millisecond)
      alert_type = if time > 0, do: "alert matching", else: "alert matching (bad time)"
      "#{alert_type} #{alert_filter_duration_type}, time=#{time} alert_count=#{length(alerts)}"
    end)

    :ok
  end

  defp schedule_notifications(alerts) do
    options = [ordered: false, timeout: 600_000]

    alerts
    |> Task.async_stream(&schedule_notification(&1), options)
    |> Stream.run()
  end

  defp schedule_notification(%Alert{} = alert) do
    matched_subscriptions = determine_recipients(alert)
    schedule_distinct_notifications(alert, matched_subscriptions)
  end

  @doc """
  determine_recipients/1 receives an alert and applies relevant filters to exclude users who should not be notified
  """
  @spec determine_recipients(Alert.t(), DateTime.t()) :: [Subscription.t()]
  def determine_recipients(alert, now \\ Calendar.DateTime.now!("America/New_York")) do
    subscriptions_to_test = Subscription.all_active_for_alert(alert)
    recent_outdated_notifications = Notification.most_recent_if_outdated_for_alert(alert)

    subscriptions_to_auto_resend =
      SentAlertFilter.filter(alert, recent_outdated_notifications, now)

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
    |> reject_users_with_no_communication_mode()
    |> Scheduler.schedule_notifications(alert)
  end

  defp reject_users_with_no_communication_mode(subscriptions_by_user) do
    subscriptions_by_user
    |> Enum.reject(fn {user, _subscriptions} -> user.communication_mode == "none" end)
  end
end
