defmodule AlertProcessor.Dissemination.NotificationSender do
  @moduledoc "Handles the sending of notifications via email or SMS."

  alias AlertProcessor.Aws.AwsClient
  alias AlertProcessor.Model.Notification
  @mailer Application.fetch_env!(:alert_processor, :mailer)
  @mailer_email Application.fetch_env!(:alert_processor, :mailer_email)
  @mailer_error Application.fetch_env!(:alert_processor, :mailer_error)

  @spec email(Notification.t()) :: {:ok, term} | {:error, term}
  def email(%Notification{} = notification) do
    {_email, response} =
      notification
      |> @mailer_email.notification_email()
      |> @mailer.deliver_now(response: true)

    {:ok, response}
  rescue
    error in @mailer_error -> {:error, error}
  end

  @spec sms(Notification.t()) :: {:ok, term} | {:error, term}
  def sms(%Notification{header: header, type: type, phone_number: phone_number}) do
    header
    |> format_sms_message(type)
    |> ExAws.SNS.publish(phone_number: "+1#{phone_number}")
    |> AwsClient.request()
  end

  @spec format_sms_message(String.t(), atom) :: String.t()
  defp format_sms_message(header, :all_clear) do
    "All clear (re: #{header})"
  end

  defp format_sms_message(header, :reminder) do
    "Reminder: #{header}"
  end

  defp format_sms_message(header, :update) do
    "Update: #{header}"
  end

  defp format_sms_message(header, _), do: header
end
