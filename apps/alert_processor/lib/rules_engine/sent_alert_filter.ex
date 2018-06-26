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
  @spec filter([Subscription.t], Alert.t, [Notification.t], DateTime.t) :: {[Subscription.t], [Subscription.t]}
  def filter(subscriptions, alert, notifications, now) do
    sent_notifications =
      Enum.filter(notifications, & &1.alert_id == alert.id)

    subscriptions_to_resend =
      subscriptions_to_resend(sent_notifications, alert.last_push_notification, now)

    subscriptions_to_test =
      subscriptions_to_test(subscriptions, sent_notifications)

    {subscriptions_to_test, subscriptions_to_resend}
  end

  defp subscriptions_to_resend(notifications, last_push_notification, now) do
    Enum.reduce(notifications, [], fn(notification, subscriptions_to_notify) ->
      case DateTime.compare(notification.last_push_notification, last_push_notification) do
        :lt ->
          notification.subscriptions
          |> notification_window_filter(now)
          |> Enum.concat(subscriptions_to_notify)
        _ ->
          subscriptions_to_notify
      end
    end)
  end

  defp subscriptions_to_test(subscriptions, notifications) do
    notified_user_ids = MapSet.new(notifications, & &1.user_id)

    Enum.reject(subscriptions, fn subscription ->
      subscription_user_notified?(subscription, notified_user_ids)
    end)
  end

  defp notification_window_filter(subscriptions, now) do
    Enum.filter(subscriptions, fn(subscription) ->
      # We extend the subscription's end time because we only want to send
      # notifications for updates that occur between the subscription's start
      # time and it's end time plus one hour.
      modified_subscription = extend_subscription_end_time(subscription)
      NotificationWindowFilter.within_notification_window?(modified_subscription, now)
    end)
  end

  defp extend_subscription_end_time(subscription) do
    Map.update!(subscription, :end_time, fn(end_time) ->
      Time.add(end_time, :timer.hours(1), :millisecond)
    end)
  end

  defp subscription_user_notified?(%{user_id: user_id}, notified_user_ids) do
    MapSet.member?(notified_user_ids, user_id)
  end
end
