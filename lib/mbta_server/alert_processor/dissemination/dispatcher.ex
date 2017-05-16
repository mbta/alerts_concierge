defmodule MbtaServer.AlertProcessor.Dispatcher do
  @moduledoc """
  Module to handle the dissemination of notifications to proper mediums based on user subscriptions.
  """
  @ex_aws Application.get_env(:mbta_server, :ex_aws)

  alias MbtaServer.AlertProcessor.{Model.Notification, NotificationMailer, NotificationSmser}

  @type ex_aws_success :: {:ok, map}
  @type ex_aws_error :: {:error, map}
  @type request_error :: {:error, String.t}

  @doc """
  send_notification/1 receives a map of user information and notification to
  delegate to the proper api.
  """
  @spec send_notification(Notification.t) ::
  ex_aws_success | ex_aws_error | request_error
  def send_notification(%Notification{message: message, email: email, phone_number: phone_number}) do
    do_send_notification(email, phone_number, message)
  end

  def send_notification(_) do
    {:error, "invalid or missing params"}
  end

  @spec do_send_notification(String.t, String.t, nil) :: request_error
  defp do_send_notification(_, _, nil) do
    {:error, "no notification"}
  end

 defp do_send_notification(nil, nil, _) do
    {:error, "no contact information"}
  end

  defp do_send_notification(nil, phone_number, notification) do
    notification
    |> NotificationSmser.notification_sms(phone_number)
    |> @ex_aws.request([])
  end

  defp do_send_notification(email, nil, notification) do
    email = notification
    |> NotificationMailer.notification_email(email)
    |> NotificationMailer.deliver_later
    {:ok, email}
  end

  defp do_send_notification(email, phone_number, notification) do
    notification
    |> NotificationMailer.notification_email(email)
    |> NotificationMailer.deliver_later
    notification
    |> NotificationSmser.notification_sms(phone_number)
    |> @ex_aws.request([])
  end
end
