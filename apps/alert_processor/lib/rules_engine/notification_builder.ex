defmodule AlertProcessor.NotificationBuilder do
  @moduledoc """
  Responsible for construction of Notifications from an Alert and Subscription
  """

  alias AlertProcessor.TextReplacement
  alias AlertProcessor.Model.Notification

  def build_notification({user, subscriptions}, alert) do
    alert = TextReplacement.replace_text(alert, subscriptions)
    %Notification{
      alert_id: alert.id,
      user: user,
      user_id: user.id,
      header: alert.header,
      service_effect: alert.service_effect,
      description: alert.description,
      url: alert.url,
      phone_number: user.phone_number,
      email: user.email,
      status: :unsent,
      last_push_notification: alert.last_push_notification,
      alert: alert,
      notification_subscriptions: Enum.map(subscriptions, & %AlertProcessor.Model.NotificationSubscription{subscription_id: &1.id}),
      closed_timestamp: alert.closed_timestamp,
      reminder?: reminder?(user, alert)
    }
  end

  defp reminder?(_user, %{reminder_times: nil}), do: false

  defp reminder?(_user, %{reminder_times: []}), do: false

  defp reminder?(user, alert, now \\ Calendar.DateTime.now!("America/New_York")) do
    any_reminder_time_earlier_than_now? =
      Enum.any?(alert.reminder_times, fn reminder_time ->
        reminder_time_earlier_than_now?(reminder_time, now)
      end)

    if any_reminder_time_earlier_than_now? do
      notification = Notification.most_recent_for_user_alert(user, alert)
      inserted_at = notification.inserted_at
      Enum.any?(alert.reminder_times, fn reminder_time ->
        reminder_time_later_than_inserted_at?(reminder_time, inserted_at)
      end)
    else
      false
    end
  end

  defp reminder_time_earlier_than_now?(reminder_time, now) do
    DateTime.compare(reminder_time, now) == :lt
  end

  defp reminder_time_later_than_inserted_at?(reminder_time, inserted_at) do
    inserted_at = DateTime.from_naive!(inserted_at, "Etc/UTC")
    DateTime.compare(reminder_time, inserted_at) == :gt
  end
end
