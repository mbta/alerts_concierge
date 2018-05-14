defmodule ConciergeSite.ConfirmationMessage do
  @moduledoc """
  Handles user confirmation messaging
  """
  alias AlertProcessor.{Aws.AwsClient, Model.Notification, NotificationSmser}
  alias ConciergeSite.Dissemination.{Email, Mailer}

  def send_email_confirmation(user) do
    user
    |> Email.confirmation_email()
    |> Mailer.deliver_later
  end

  def send_sms_confirmation("", _), do: {:ok, nil}
  def send_sms_confirmation(phone_number, "true") do
    %Notification{
      header: "You have been subscribed to MBTA alerts. To stop receiving texts, reply STOP (cannot resubscribe for 30 days) or visit alerts.mbta.com. Data rates may apply.",
      phone_number: phone_number
    }
    |> NotificationSmser.notification_sms()
    |> AwsClient.request()
  end
  def send_sms_confirmation(_, _), do: {:ok, nil}
end
