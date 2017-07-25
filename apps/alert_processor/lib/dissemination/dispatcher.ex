defmodule AlertProcessor.Dispatcher do
  @moduledoc """
  Module to handle the dissemination of notifications to proper mediums based on user subscriptions.
  """

  alias AlertProcessor.{Aws.AwsClient, Model.Notification, NotificationMailer, NotificationSmser}

  @doc """
  send_notification/1 receives a map of user information and notification to
  delegate to the proper api.
  """
  @spec send_notification(Notification.t) :: AwsClient.aws_success | AwsClient.aws_error | AwsClient.request_error
  def send_notification(%Notification{email: email, phone_number: phone_number} = notification) do
    do_send_notification(email, phone_number, notification)
  end
  def send_notification(_) do
    {:error, "invalid or missing params"}
  end

  defp do_send_notification(_, _, %Notification{header: nil}) do
    {:error, "no notification"}
  end
  defp do_send_notification(nil, nil, _) do
    {:error, "no contact information"}
  end
  defp do_send_notification(email, nil, notification) do
    email = notification
    |> NotificationMailer.notification_email(email)
    |> NotificationMailer.deliver_later
    {:ok, email}
  end
  defp do_send_notification(_email, phone_number, notification) do
    notification
    |> NotificationSmser.notification_sms(phone_number)
    |> AwsClient.request()
  end
end
