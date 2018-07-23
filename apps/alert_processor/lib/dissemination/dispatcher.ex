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
    {:ok, email}
  end

  def send_notification(
        %Notification{
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
      "SMS notification: header=#{header} user_id=#{user.id} alert_id=#{alert_id} closed_timestamp=#{
        closed_timestamp
      } result=#{inspect(result)}"
    end)

    result
  end

  def send_notification(_) do
    {:error, "invalid or missing params"}
  end
end
