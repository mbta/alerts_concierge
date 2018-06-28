defmodule AlertProcessor.NotificationBuilder do
  @moduledoc """
  Responsible for construction of Notifications from an Alert and Subscription
  """

  require Logger
  alias AlertProcessor.TextReplacement
  alias AlertProcessor.Model.Notification

  def build_notification({user, subscriptions}, alert) do
    alert_text_replaced = replace_text(alert, subscriptions)
    do_build_notification({user, subscriptions}, alert_text_replaced)
  end

  defp replace_text(alert, subscriptions) do
    case TextReplacement.replace_text(alert, subscriptions) do
      {:ok, modified_alert} ->
        modified_alert
      {:error, error} ->
        Logger.warn(fn -> "Error replacing text: alert_id=#{inspect alert.id} error=#{inspect error}" end)
        alert
    end
  end

  defp do_build_notification({user, subscriptions}, alert) do
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
      type: List.first(subscriptions).notification_type_to_send || :initial
    }
  end
end
