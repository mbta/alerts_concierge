defmodule ConciergeSite.ConfirmationMessage do
  @moduledoc """
  Handles user confirmation messaging
  """
  alias AlertProcessor.{Model.Notification, NotificationSmser}
  alias ConciergeSite.{Email, Mailer}

  @ex_aws Application.get_env(:alert_processor, :ex_aws)

  @doc """
  Sends email or SMS to uesr based on if they have a phone number
  """
  def send_confirmation(user) do
    if is_nil(user.phone_number) do
      send_email_confirmation(user)
    else
      send_sms_confirmation(user.phone_number)
    end
  end

  defp send_email_confirmation(user) do
    user.email
    |> Email.confirmation_email()
    |> Mailer.deliver_later
  end

  defp send_sms_confirmation(phone_number) do
    %Notification{header: "Thanks for signing up for MBTA Alerts. You will receive notifications for your subscriptions. Reply STOP to unsubscribe anytime"}
    |> NotificationSmser.notification_sms(phone_number)
    |> @ex_aws.request([])
  end
end
