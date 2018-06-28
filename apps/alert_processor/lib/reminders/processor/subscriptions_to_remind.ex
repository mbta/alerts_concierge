defmodule AlertProcessor.Reminders.Processor.SubscriptionsToRemind do
  @moduledoc """
  Responsible for determining which subscriptions should be sent a reminder for
  a given alert and list of most recently sent notifications.

  """

  alias AlertProcessor.NotificationWindowFilter
  alias AlertProcessor.Model.{Alert, Subscription, Notification}

  @doc """
  Accepts an alert and a list of the latest sent notifications for the given
  alert.

  A note on notifications:

  The notifications passed in as the third argument are expected to be unique
  per user, relevant to the alert in the first argument, and the latest one
  inserted to the DB (according to it's `inserted_at` value).

  """
  @spec perform({Alert.t(), [Notification.t()], DateTime.t()}) :: [Subscription.t()]
  def perform({alert, notifications, now}) do
    subscriptions_to_send_reminder(alert, notifications, now)
  end

  def subscriptions_to_send_reminder(%Alert{reminder_times: nil}, _, _), do: []

  def subscriptions_to_send_reminder(%Alert{reminder_times: []}, _, _), do: []

  def subscriptions_to_send_reminder(alert, notifications, now) do
    Enum.reduce(notifications, [], fn notification, subscriptions_to_remind ->
      if reminder_due?(notification, alert, now) do
        notification.subscriptions
        |> Enum.filter(&NotificationWindowFilter.within_notification_window?(&1, now))
        |> put_notification_type_to_send()
        |> Enum.concat(subscriptions_to_remind)
      else
        subscriptions_to_remind
      end
    end)
  end

  defp reminder_due?(notification, alert, now) do
    inserted_at = notification.inserted_at

    Enum.any?(alert.reminder_times, fn reminder_time ->
      reminder_time_earlier_than_now?(reminder_time, now) &&
        reminder_time_later_than_inserted_at?(reminder_time, inserted_at)
    end)
  end

  defp reminder_time_earlier_than_now?(reminder_time, now) do
    DateTime.compare(reminder_time, now) == :lt
  end

  defp reminder_time_later_than_inserted_at?(reminder_time, inserted_at) do
    inserted_at = DateTime.from_naive!(inserted_at, "Etc/UTC")
    DateTime.compare(reminder_time, inserted_at) == :gt
  end

  defp put_notification_type_to_send(subscriptions) do
    Enum.map(subscriptions, fn subscription ->
      Map.put(subscription, :notification_type_to_send, :reminder)
    end)
  end
end
