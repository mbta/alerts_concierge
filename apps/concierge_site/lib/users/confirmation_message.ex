defmodule ConciergeSite.ConfirmationMessage do
  @moduledoc """
  Handles user confirmation messaging
  """
  alias AlertProcessor.{Aws.AwsClient, Model.Notification, NotificationSmser}
  alias ConciergeSite.Dissemination.{Email, Mailer}

  @doc """
  Sends email or SMS to uesr based on if they have a phone number
  """
  def send_confirmation(user) do
    unless is_nil(user.phone_number) do
      send_sms_confirmation(user.phone_number)
    end
    send_email_confirmation(user)
  end

  defp send_email_confirmation(user) do
    user
    |> Email.confirmation_email()
    |> Mailer.deliver_later
  end

  defp send_sms_confirmation(phone_number) do
    %Notification{
      header: "You have been subscribed to MBTA alerts. To stop receiving texts, reply STOP (cannot resubscribe for 30 days) or visit alerts.mbta.com. Data rates may apply.",
      phone_number: phone_number
    }
    |> NotificationSmser.notification_sms()
    |> AwsClient.request()
  end
end
