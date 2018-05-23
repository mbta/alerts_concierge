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
  def filter(subscriptions, alert, notifications, now \\ Calendar.DateTime.now!("America/New_York")) do
    do_filter(subscriptions, alert, notifications, now)
  end

  defp do_filter(subscriptions, %Alert{id: alert_id, last_push_notification: lpn}, notifications, now) do
    sent_matching_notifications =
      Enum.filter(notifications, fn (n) -> alert_id == n.alert_id && n.status == :sent end)

    subscriptions_to_auto_resend =
      subscriptions_to_auto_resend(subscriptions, sent_matching_notifications, lpn, now)

    subscription_ids = MapSet.new(subscriptions, fn (s) -> s.id end)

    has_been_sent_user_id_set = sent_matching_notifications
    |> Enum.filter(fn (n) ->
      case n.subscriptions do
        [] -> true
        subs -> Enum.any?(subs, fn (s) -> MapSet.member?(subscription_ids, s.id) end)
      end
    end)
    |> MapSet.new(fn (n) -> n.user_id end)

    subscriptions_to_test =
      Enum.reject(subscriptions, fn (s) -> MapSet.member?(has_been_sent_user_id_set, s.user_id) end)

    {subscriptions_to_test, subscriptions_to_auto_resend}
  end

  defp subscriptions_to_auto_resend(subscriptions, notifications, last_push_notification, now) do
    subscription_ids_to_notify =
      notifications
      |> subscriptions_to_notify_of_update(last_push_notification, now)
      |> MapSet.new(fn(subscription) -> subscription.id end)

    Enum.filter(subscriptions, fn(subscription) ->
      MapSet.member?(subscription_ids_to_notify, subscription.id)
    end)
  end

  defp subscriptions_to_notify_of_update(notifications, last_push_notification, now) do
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
end
