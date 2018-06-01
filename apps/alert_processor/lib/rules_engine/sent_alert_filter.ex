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

  The notifications passed in as the third argument are expected to be unique
  per user, relevant to the alert in the second argument, and the latest one
  inserted to the DB (according to it's `inserted_at` value).  This is to make
  sure we can correctly match for updates (where the `last_push_notification`
  changes) and reminders.
  """
  @spec filter([Subscription.t], Alert.t, [Notification.t], DateTime.t) :: {[Subscription.t], [Subscription.t]}
  def filter(subscriptions, alert, notifications, now \\ Calendar.DateTime.now!("America/New_York")) do
    do_filter(subscriptions, alert, notifications, now)
  end

  defp do_filter(subscriptions, alert, notifications, now) do
    alert_id = alert.id
    lpn = alert.last_push_notification

    sent_matching_notifications =
      Enum.filter(notifications, fn (n) -> alert_id == n.alert_id && n.status == :sent end)

    subscriptions_to_auto_resend =
      subscriptions_to_auto_resend(subscriptions, alert, sent_matching_notifications, lpn, now)

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

  defp subscriptions_to_auto_resend(subscriptions, alert, notifications, last_push_notification, now) do
    subscription_ids_to_update =
      subscription_ids_to_update(notifications, last_push_notification, now)
    subscription_ids_to_remind =
      subscription_ids_to_remind(notifications, alert, now)
    subscription_ids_to_notify =
      MapSet.union(subscription_ids_to_update, subscription_ids_to_remind)
    Enum.filter(subscriptions, fn(subscription) ->
      MapSet.member?(subscription_ids_to_notify, subscription.id)
    end)
  end

  defp subscription_ids_to_update(notifications, last_push_notification, now) do
    notifications
    |> subscriptions_to_send_update(last_push_notification, now)
    |> MapSet.new(fn(subscription) -> subscription.id end)
  end

  defp subscriptions_to_send_update(notifications, last_push_notification, now) do
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

  defp subscription_ids_to_remind(_, %Alert{reminder_times: nil}, _) do
    MapSet.new()
  end

  defp subscription_ids_to_remind(_, %Alert{reminder_times: []}, _) do
    MapSet.new()
  end

  defp subscription_ids_to_remind(notifications, alert, now) do
    notifications
    |> subscriptions_to_send_reminder(alert, now)
    |> MapSet.new(fn(subscription) -> subscription.id end)
  end

  defp subscriptions_to_send_reminder(notifications, alert, now) do
    Enum.reduce(notifications, [], fn(notification, subscriptions_to_notify) ->
      if reminder_due?(notification, alert, now) do
        notification.subscriptions
        |> Enum.filter(& NotificationWindowFilter.within_notification_window?(&1, now))
        |> Enum.concat(subscriptions_to_notify)
      else
        subscriptions_to_notify
      end
    end)
  end

  defp reminder_due?(notification, alert, now) do
    inserted_at = notification.inserted_at
    Enum.any?(alert.reminder_times, fn reminder_time ->
      reminder_time_earlier_than_now?(reminder_time, now)
      && reminder_time_later_than_inserted_at?(reminder_time, inserted_at)
    end)
  end

  defp reminder_time_earlier_than_now?(reminder_time, now) do
    DateTime.compare(reminder_time, now) == :lt
  end

  defp reminder_time_later_than_inserted_at?(reminder_time, inserted_at) do
    inserted_at = DateTime.from_naive!(inserted_at, "Etc/UTC")
    DateTime.compare(reminder_time, inserted_at) == :gt
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
