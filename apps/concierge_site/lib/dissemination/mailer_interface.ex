defmodule ConciergeSite.Dissemination.MailerInterface do
  @moduledoc """
  Interface for the AlertProcessor app to send emails through the ConciergeSite mailer without an
  explicit dependency on this app (which would create a cyclic dependency error).
  """
  use GenServer
  alias ConciergeSite.Dissemination.{NotificationEmail, Mailer}

  @lookup_tuple {:via, Registry, {:mailer_process_registry, :mailer}}

  def start_link(opts \\ [name: @lookup_tuple]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    {:ok, nil}
  end

  def handle_call({:send_notification_email, notification}, _from, _state) do
    {_email, response} =
      notification
      |> NotificationEmail.notification_email()
      |> Mailer.deliver_now(response: true)

    {:reply, {:ok, response}, nil}
  rescue
    error in Bamboo.ApiError ->
      {:reply, {:error, error}, nil}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
