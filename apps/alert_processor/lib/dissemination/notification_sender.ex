defmodule AlertProcessor.Dissemination.NotificationSender do
  @moduledoc "Sends individual notifications to their email or SMS destinations."

  alias AlertProcessor.Aws.AwsClient
  alias AlertProcessor.Model.Notification

  require Logger

  @mailer Application.fetch_env!(:alert_processor, :mailer)
  @mailer_email Application.fetch_env!(:alert_processor, :mailer_email)
  @mailer_error Application.fetch_env!(:alert_processor, :mailer_error)

  @doc "Sends a notification, via SMS if it has a phone number, else via email."
  @spec send(Notification.t()) :: {:ok, term} | {:error, term}
  def send(%Notification{email: email, phone_number: nil} = notification)
      when not is_nil(email) do
    {_email, response} =
      notification
      |> @mailer_email.notification_email()
      |> @mailer.deliver_now(response: true)

    log(notification, :email, :ok, response)
    {:ok, response}
  rescue
    error in @mailer_error ->
      log(notification, :email, :error, error)
      {:error, error}

    error in ArgumentError ->
      Logger.warn("invalid email for #{notification.user_id}")
      {:error, error}
  end

  def send(%Notification{phone_number: phone_number} = notification)
      when not is_nil(phone_number) do
    {result, response} =
      notification
      |> sms_message()
      |> ExAws.SNS.publish(phone_number: "+1#{phone_number}")
      |> AwsClient.request()

    log(notification, :sms, result, response)
    {result, response}
  end

  @spec sms_message(Notification.t()) :: String.t()
  defp sms_message(%{type: :all_clear, header: header}), do: "All clear (re: #{header})"
  defp sms_message(%{type: :reminder, header: header}), do: "Reminder: #{header}"
  defp sms_message(%{type: :update, header: header}), do: "Update: #{header}"
  defp sms_message(%{header: header}), do: header

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
         communication_mode,
         result,
         response
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

  defp log(notification, _, _, _) do
    Logger.info("notification sent: logging function did not match #{inspect(notification)}")
  end
end
