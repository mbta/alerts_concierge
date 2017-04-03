defmodule MbtaServer.AlertProcessor.Messager do
  @moduledoc """
  Module to handle the dissemination of messages to proper mediums based on user subscriptions.
  """
  @type message_params :: {String.t, String.t | nil, String.t | nil}

  @ex_aws Application.get_env(:mbta_server, :ex_aws)

  alias MbtaServer.{AlertMessageMailer, Mailer}
  alias MbtaServer.AlertProcessor.{AlertMessageSmser}

  @doc """
  send_alert_message/1 receives a map of user information and message to
  delegate to the proper api.
  """
  @spec send_alert_message(message_params) :: {:ok, Map} | {:error, Map} | {:error, String.t}
  def send_alert_message(params) do
    case params do
      {message, email, phone_number} ->
        send_alert_message(email, phone_number, message)
      _ ->
        {:error, "invalid or missing params"}
    end
  end

  @spec send_alert_message(String.t, String.t, nil) :: {:error, String.t}
  defp send_alert_message(_, _, nil) do
    {:error, "no message"}
  end

  @spec send_alert_message(nil, nil, String.t) :: {:error, String.t}
  defp send_alert_message(nil, nil, _) do
    {:error, "no contact information"}
  end

  @spec send_alert_message(nil, String.t, String.t) :: {:ok, Map} | {:error, Map}
  defp send_alert_message(nil, phone_number, message) do
    AlertMessageSmser.alert_message_sms(message, phone_number) |> @ex_aws.request([])
  end

  @spec send_alert_message(String.t, nil, String.t) :: {:ok, Map} | {:error, Map}
  defp send_alert_message(email, nil, message) do
    email = AlertMessageMailer.alert_message_email(message, email) |> Mailer.deliver_later
    {:ok, email}
  end

  @spec send_alert_message(String.t, String.t, String.t) :: {:ok, Map} | {:error, Map}
  defp send_alert_message(email, phone_number, message) do
    AlertMessageMailer.alert_message_email(message, email) |> Mailer.deliver_later
    AlertMessageSmser.alert_message_sms(message, phone_number) |> @ex_aws.request([])
  end
end
