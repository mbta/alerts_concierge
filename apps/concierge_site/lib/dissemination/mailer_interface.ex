defmodule ConciergeSite.Dissemination.MailerInterface do
  @moduledoc """
  interface for receiving email requests from alert processor app
  and dispatches to correct mailer
  """
  use GenServer
  require Logger
  alias ConciergeSite.Dissemination.{DigestEmail, NotificationEmail, Mailer}

  @lookup_tuple {:via, Registry, {:mailer_process_registry, :mailer}}

  def start_link(opts \\ [name: @lookup_tuple]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:send_notification_email, notification}, _from, _state) do
    response =
      notification
      |> NotificationEmail.notification_email()
      |> Mailer.deliver_later()
    Logger.info(fn -> "Notification Email result: #{inspect(response)}, alert_id: #{notification.alert_id}, user_id: #{notification.user.id}," end)
    {:reply, response, nil}
  end

  def handle_call({:send_digest_email, digest_message}, _from, _state) do
    response =
      digest_message
      |> DigestEmail.digest_email()
      |> Mailer.deliver_later()
    Logger.info(fn -> "Digest Email result: #{inspect(response)}, user_id: #{digest_message.user.id}" end)
    {:reply, response, nil}
  end
end
