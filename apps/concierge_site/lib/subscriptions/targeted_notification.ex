defmodule ConciergeSite.TargetedNotification do
  @moduledoc """
  Handles targeted notification via email or sms to subscriber
  """
  alias AlertProcessor.{Aws.AwsClient, Model.Notification, NotificationSmser}
  alias ConciergeSite.Dissemination.{Email, Mailer}

  def send_targeted_notification(message) do
    if message["carrier"] == "email" do
      send_email(message["subscriber_email"], message["subject"], message["email_body"])
    else
      send_sms(message)
    end
  end

  defp send_email(email, subject, body) do
    Email.targeted_notification_email(email, subject, body)
    |> Mailer.deliver_later
  end

  defp send_sms(message) do
    %Notification{
      header: message["sms_body"],
      phone_number: message["subscriber_phone_number"]
    }
    |> NotificationSmser.notification_sms()
    |> AwsClient.request()
  end
end
