defmodule AlertProcessor.SentAlertFilter do
  @moduledoc """
  Filter users to receive alert based on having previously received alert
  """
  alias AlertProcessor.Model.{Alert, Subscription}

  @doc """
  Takes a single alert, a list of subscriptions, and a list of notifications. Returns the list of subscriptions
  that have not already recieved a notification for the alert, or that have already recieved a notification
  but with an older last_push_notification
  """
  @spec filter([Subscription.t], Keyword.t) :: [Subscription.t]
  def filter(subscriptions, alert: alert, notifications: notifications) do
    SystemMetrics.Tracer.trace(fn() ->
      do_filter(subscriptions, alert, notifications)
    end, "sent_alert_filter")
  end

  defp do_filter(subscriptions, %Alert{id: alert_id, last_push_notification: lpn}, notifications) do
    notifications_to_not_resend = Enum.filter(notifications, fn(notification) ->
      alert_id == notification.alert_id &&
      (notification.status == :sent && same?(lpn, notification.last_push_notification))
    end)

    Enum.reject(subscriptions, fn(sub) ->
      Enum.any?(notifications_to_not_resend, &(&1.user_id == sub.user.id))
    end)
  end

  defp same?(lpn, notification_lpn) do
    DateTime.compare(lpn, notification_lpn) != :gt
  end
end
