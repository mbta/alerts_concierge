defmodule AlertProcessor.Dispatcher do
  @moduledoc """
  Module to handle the dissemination of notifications to proper mediums based on user subscriptions.
  """

  @mailer Application.get_env(:alert_processor, :mailer)
  alias AlertProcessor.{Aws.AwsClient, Model.Notification, NotificationSmser}
  require Logger

  @doc """
  send_notification/1 receives a map of user information and notification to
  delegate to the proper api.
  """
  @spec send_notification(Notification.t()) :: AwsClient.response()
  def send_notification(%Notification{header: nil}) do
    {:error, "no notification"}
  end

  def send_notification(%Notification{email: nil, phone_number: nil}) do
    {:error, "no contact information"}
  end

  def send_notification(%Notification{email: email, phone_number: nil} = notification)
      when not is_nil(email) do
    email = @mailer.send_notification_email(notification)
    log(notification)
    {:ok, email}
  end

  def send_notification(
        %Notification{
          id: notification_id,
          phone_number: phone_number,
          header: header,
          closed_timestamp: closed_timestamp,
          alert_id: alert_id,
          user: user
        } = notification
      )
      when not is_nil(phone_number) do
    result =
      notification
      |> NotificationSmser.notification_sms()
      |> AwsClient.request()

    Logger.info(fn ->
      "SMS notification: notification_id=#{notification_id} header=#{header} user_id=#{user.id} alert_id=#{
        alert_id
      } closed_timestamp=#{closed_timestamp} result=#{inspect(result)}"
    end)

    log(notification)

    result
  end

  def send_notification(_) do
    {:error, "invalid or missing params"}
  end

  defp log(%{
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
       })
       when not is_nil(alert_fetched_at) and not is_nil(alert_updated_at) do
    Logger.info(fn ->
      now = DateTime.utc_now()

      %{
        id: notification_id,
        type: notification_type,
        user_id: user_id,
        alert_id: alert_id,
        alert_severity: alert_severity,
        alert_duration_type: alert_duration_type,
        seconds_processing: DateTime.diff(now, alert_fetched_at, :millisecond) / 1000,
        seconds_since_alert_update: DateTime.diff(now, alert_updated_at)
      }
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
      |> Enum.join(" ")
      |> String.replace_prefix("", "notification sent: ")
    end)
  end

  defp log(notification) do
    Logger.info("notification sent: logging function did not match #{inspect(notification)}")
  end
end
