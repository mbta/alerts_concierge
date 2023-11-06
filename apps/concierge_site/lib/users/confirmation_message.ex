defmodule ConciergeSite.ConfirmationMessage do
  @moduledoc """
  Handles user confirmation messaging
  """
  require Logger

  alias AlertProcessor.Model.Notification
  alias AlertProcessor.Dissemination.NotificationSender
  alias ConciergeSite.Dissemination.{Email, Mailer}

  def send_email_confirmation(user) do
    Logger.info("Sending welcome message via=email")

    user
    |> Email.confirmation_email()
    |> Mailer.deliver_later()
  end

  def send_sms_confirmation("", _), do: {:ok, nil}

  def send_sms_confirmation(phone_number, "true") do
    Logger.info("Sending welcome message via=sms")

    %Notification{
      header:
        "You have been subscribed to T-Alerts. " <>
          "To stop receiving texts, reply STOP (cannot resubscribe for 30 days) " <>
          "or visit alerts.mbta.com. Data rates may apply.",
      phone_number: phone_number
    }
    |> NotificationSender.send()
  end

  def send_sms_confirmation(_, _), do: {:ok, nil}
end
