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
  @spec filter([Subscription.t], Keyword.t) :: {[Subscription.t], [Subscription.t]}
  def filter(subscriptions, alert: alert, notifications: notifications) do
    do_filter(subscriptions, alert, notifications)
  end

  defp do_filter(subscriptions, %Alert{id: alert_id, last_push_notification: lpn,
    closed_timestamp: closed_timestamp}, notifications) do

    sent_matching_notifications =
      Enum.filter(notifications, fn (n) -> alert_id == n.alert_id && n.status == :sent end)

    resend_subscription_id_set = sent_matching_notifications
    |> Enum.filter(fn (n) -> new_or_closed?(lpn, closed_timestamp, n) end)
    |> Enum.flat_map(fn (n) -> n.subscriptions end)
    |> MapSet.new(fn (n) -> n.id end)

    subscriptions_to_auto_resend =
      Enum.filter(subscriptions, fn (s) -> MapSet.member?(resend_subscription_id_set, s.id) end)

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

  defp new?(lpn, notification_lpn) do
    DateTime.compare(lpn, notification_lpn) == :gt
  end

  defp closed?(nil, nil), do: false
  defp closed?(_, nil), do: true
  defp closed?(nil, _), do: true
  defp closed?(alert_closed, subscription_closed) do
    new?(alert_closed, subscription_closed)
  end

  defp new_or_closed?(lpn, closed_timestamp, notification) do
    new?(lpn, notification.last_push_notification) || closed?(closed_timestamp, notification.closed_timestamp)
  end
end
