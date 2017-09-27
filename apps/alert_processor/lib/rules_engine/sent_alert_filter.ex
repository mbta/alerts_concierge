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
    {notifications_to_resend, notifications_to_not_resend} =
      Enum.split_with(notifications, fn(n) ->
        alert_id == n.alert_id && n.status == :sent && new?(lpn, n.last_push_notification)
      end)

    {subscriptions_to_auto_resend, subscriptions_to_consider} =
      Enum.split_with(subscriptions, fn(sub) ->
        Enum.any?(notifications_to_resend, & Enum.member?(&1.subscription_ids, sub.id) && &1.alert_id == alert_id && &1.status == :sent)
      end)

    subscriptions_to_test =
      Enum.reject(subscriptions_to_consider, fn(sub) ->
        Enum.any?(notifications_to_not_resend, & &1.user_id == sub.user.id && &1.alert_id == alert_id && &1.status == :sent) ||
        Enum.any?(subscriptions_to_auto_resend, & &1.user_id == sub.user_id)
      end)

    {subscriptions_to_test, subscriptions_to_auto_resend}
  end

  defp new?(lpn, notification_lpn) do
    DateTime.compare(lpn, notification_lpn) == :gt
  end
end
