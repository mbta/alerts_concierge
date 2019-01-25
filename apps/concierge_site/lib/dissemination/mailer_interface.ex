defmodule ConciergeSite.Dissemination.MailerInterface do
  @moduledoc """
  interface for receiving email requests from alert processor app
  and dispatches to correct mailer
  """
  use GenServer
  require Logger
  alias ConciergeSite.Dissemination.{NotificationEmail, Mailer}

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

    Logger.info(fn ->
      "Notification Email result: alert_id: #{notification.alert_id}, user_id: #{
        notification.user.id
      }, notification_id: #{notification.id}"
    end)

    {:reply, response, nil}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
