defmodule ConciergeSite.NotificationFactory do
  @moduledoc """
  Standard interface for generating notifications
  """

  alias AlertProcessor.Model.Notification
  alias AlertProcessor.Model.Alert

  def notification(alert, subscriptions) do
    %Notification{alert_id: alert.id, status: :sent, last_push_notification: alert.last_push_notification, subscriptions: subscriptions}
  end

  def notification(:earlier, alert, subscriptions) do
    %Notification{alert_id: alert.id, status: :sent, last_push_notification: earlier_push_notification(alert), subscriptions: subscriptions}
  end

  defp earlier_push_notification(%Alert{last_push_notification: datetime}) do
    timestamp = DateTime.to_unix(datetime)

    timestamp - 60 * 60 * 24
    |> DateTime.from_unix!
  end
end