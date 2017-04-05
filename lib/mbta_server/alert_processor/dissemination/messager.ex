defmodule MbtaServer.AlertProcessor.Messager do
  @moduledoc """
  Module to handle the dissemination of messages to proper mediums based on user subscriptions.
  """
  @type message_params :: {String.t, String.t | nil, String.t | nil}

  @ex_aws Application.get_env(:mbta_server, :ex_aws)

  alias MbtaServer.{AlertMessageMailer, Mailer}
  alias MbtaServer.AlertProcessor.AlertMessageSmser

  @doc """
  send_alert_message/1 receives a map of user information and message to
  delegate to the proper api.
  """
  @spec send_alert_message(message_params) :: {:ok, Map} | {:error, Map} | {:error, String.t}
  def send_alert_message({message, email, phone_number}) do
    do_send_alert_message(email, phone_number, message)
  end

  def send_alert_message(_) do
    {:error, "invalid or missing params"}
  end

  @spec do_send_alert_message(String.t, String.t, nil) :: {:error, String.t}
  defp do_send_alert_message(_, _, nil) do
    {:error, "no message"}
  end

  @spec do_send_alert_message(nil, nil, String.t) :: {:error, String.t}
  defp do_send_alert_message(nil, nil, _) do
    {:error, "no contact information"}
  end

  @spec do_send_alert_message(nil, String.t, String.t) :: {:ok, Map} | {:error, Map}
  defp do_send_alert_message(nil, phone_number, message) do
    message |> AlertMessageSmser.alert_message_sms(phone_number) |> @ex_aws.request([])
  end

  @spec do_send_alert_message(String.t, nil, String.t) :: {:ok, Map} | {:error, Map}
  defp do_send_alert_message(email, nil, message) do
    email = message |> AlertMessageMailer.alert_message_email(email) |> Mailer.deliver_later
    {:ok, email}
  end

  @spec do_send_alert_message(String.t, String.t, String.t) :: {:ok, Map} | {:error, Map}
  defp do_send_alert_message(email, phone_number, message) do
    message |> AlertMessageMailer.alert_message_email(email) |> Mailer.deliver_later
    message |> AlertMessageSmser.alert_message_sms(phone_number) |> @ex_aws.request([])
  end
end
