defmodule AlertProcessor.Dispatcher do
  @moduledoc """
  Module to handle the dissemination of notifications to proper mediums based on user subscriptions.
  """

  alias AlertProcessor.Model.Notification
  alias AlertProcessor.Dissemination.NotificationSender
  require Logger

  @doc "Sends the given Notification, via SMS if it has a phone number, else via email."
  @spec send_notification(Notification.t()) :: {:ok, term} | {:error, term}
  def send_notification(%Notification{email: email, phone_number: nil} = notification)
      when not is_nil(email) do
    result = NotificationSender.email(notification)
    log(notification, result, :email)
    result
  end

  def send_notification(%Notification{phone_number: phone_number} = notification)
      when not is_nil(phone_number) do
    result = NotificationSender.sms(notification)
    log(notification, result, :sms)
    result
  end

  def send_notification(_) do
    {:error, "invalid or missing params"}
  end

  defp log(
         %{
           id: notification_id,
           type: notification_type,
           user_id: user_id,
           alert: %{
             id: alert_id,
             last_push_notification: alert_updated_at,
             severity: alert_severity,
             tracking_duration_type: alert_duration_type,
             tracking_fetched_at: alert_fetched_at
           }
         },
         {result, response},
         communication_mode
       )
       when not is_nil(alert_fetched_at) and not is_nil(alert_updated_at) do
    Logger.info(fn ->
      now = DateTime.utc_now()

      %{
        id: notification_id,
        type: notification_type,
        mode: communication_mode,
        result: result,
        user_id: user_id,
        alert_id: alert_id,
        alert_severity: alert_severity,
        alert_duration_type: alert_duration_type,
        seconds_processing: DateTime.diff(now, alert_fetched_at, :millisecond) / 1000,
        seconds_since_alert_update: DateTime.diff(now, alert_updated_at),
        response: inspect(response)
      }
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
      |> Enum.join(" ")
      |> String.replace_prefix("", "notification sent: ")
    end)
  end

  defp log(notification, {_, _}, _) do
    Logger.info("notification sent: logging function did not match #{inspect(notification)}")
  end
end
