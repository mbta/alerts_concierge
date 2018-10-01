defmodule AlertProcessor.SentAlertFilter do
  @moduledoc """
  Filter users to receive alert based on having previously received alert
  """
  alias AlertProcessor.NotificationWindowFilter
  alias AlertProcessor.Model.{Alert, Subscription, Notification}

  @doc """
  Takes a single alert, a list of subscriptions, and a list of notifications. Returns the list of subscriptions
  that have not already recieved a notification for the alert, or that have already recieved a notification
  but with an older last_push_notification
  """
  @spec filter(Alert.t(), [Notification.t()], DateTime.t()) :: [Subscription.t()]
  def filter(alert, recent_outdated_notifications, now),
    do: subscriptions_to_resend(recent_outdated_notifications, alert, now)

  defp subscriptions_to_resend(recent_outdated_notifications, alert, now) do
    recent_outdated_notifications
    |> Enum.map(fn notification ->
      notification.subscriptions
      |> notification_window_filter(now)
      |> put_notification_type_to_send(alert)
    end)
    |> List.flatten()
  end

  defp notification_window_filter(subscriptions, now) do
    Enum.filter(subscriptions, fn subscription ->
      # We extend the subscription's end time because we only want to send
      # notifications for updates that occur between the subscription's start
      # time and it's end time plus one hour.
      modified_subscription = extend_subscription_end_time(subscription)
      NotificationWindowFilter.within_notification_window?(modified_subscription, now)
    end)
  end

  defp extend_subscription_end_time(subscription) do
    Map.update!(subscription, :end_time, fn end_time ->
      Time.add(end_time, :timer.hours(1), :millisecond)
    end)
  end

  defp put_notification_type_to_send(subscriptions, alert) do
    notification_type = if alert.closed_timestamp, do: :all_clear, else: :update

    Enum.map(subscriptions, fn subscription ->
      Map.put(subscription, :notification_type_to_send, notification_type)
    end)
  end
end
