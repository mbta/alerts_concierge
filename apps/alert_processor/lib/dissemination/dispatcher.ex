defmodule AlertProcessor.Dispatcher do
  @moduledoc """
  Module to handle the dissemination of notifications to proper mediums based on user subscriptions.
  """

  alias AlertProcessor.{Aws.AwsClient, MailHelper, Model.Notification, NotificationMailer, NotificationSmser}

  @doc """
  send_notification/1 receives a map of user information and notification to
  delegate to the proper api.
  """
  @spec send_notification(Notification.t) :: AwsClient.response
  def send_notification(%Notification{header: nil}) do
    {:error, "no notification"}
  end
  def send_notification(%Notification{email: nil, phone_number: nil}) do
    {:error, "no contact information"}
  end
  def send_notification(%Notification{email: email, phone_number: nil} = notification) when not is_nil(email) do
    unsubscribe_url = MailHelper.unsubscribe_url(notification.user)
    email =
      notification
      |> NotificationMailer.notification_email(unsubscribe_url)
      |> NotificationMailer.deliver_later()
    {:ok, email}
  end
  def send_notification(%Notification{phone_number: phone_number} = notification) when not is_nil(phone_number) do
    notification
    |> NotificationSmser.notification_sms()
    |> AwsClient.request()
  end
  def send_notification(_) do
    {:error, "invalid or missing params"}
  end
end
