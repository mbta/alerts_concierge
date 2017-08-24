defmodule AlertProcessor.SentAlertFilter do
  @moduledoc """
  Filter users to receive alert based on having previously received alert
  """

  alias AlertProcessor.Model.{Alert, Notification, Subscription}

  @doc """
  Takes a single alert, a list of subscriptions, and a list of notifications. Returns the list of subscriptions
  that have not already recieved a notification for the alert, or that have already recieved a notification
  but with an older last_push_notification
  """
  @spec filter({Alert.t, [Subscription.t], [Notification.t]}) :: {:ok, [Subscription.t], Alert.t}
  def filter({%Alert{id: alert_id, last_push_notification: lpn} = alert, subscriptions, notifications}) do
    notifications_to_not_resend = Enum.filter(notifications, fn(notification) ->
      alert_id == notification.alert_id &&
      (notification.status == :sent && lpn == notification.last_push_notification)
    end)

    matching_subscriptions = Enum.reject(subscriptions, fn(sub) ->
      Enum.any?(notifications_to_not_resend, &(&1.user_id == sub.user.id))
    end)

    {:ok, matching_subscriptions, alert}
  end
end
