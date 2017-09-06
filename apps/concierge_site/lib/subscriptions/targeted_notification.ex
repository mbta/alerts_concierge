defmodule ConciergeSite.TargetedNotification do
  @moduledoc """
  Handles targeted notification via email or sms to subscriber
  """
  alias AlertProcessor.{Aws.AwsClient, Model.Notification, NotificationSmser}
  alias ConciergeSite.Dissemination.{Email, Mailer}

  def send_targeted_notification(subscriber, message)
  def send_targeted_notification(subscriber, %{"carrier" => "email"} = message) do
    send_email(subscriber.email, message["subject"], message["email_body"])
  end
  def send_targeted_notification(subscriber, %{"carrier" => "sms"} = message) do
    send_sms(subscriber.phone_number, message)
  end

  defp send_email(email, subject, body) do
    email
    |> Email.targeted_notification_email(subject, body)
    |> Mailer.deliver_later
  end

  defp send_sms(phone_number, message) do
    %Notification{
      header: message["sms_body"],
      phone_number: phone_number
    }
    |> NotificationSmser.notification_sms()
    |> AwsClient.request()
  end
end
