defmodule AlertProcessor.Disemmination.Mailer do
  @moduledoc """
  interface for sending emails from alert processor app
  """
  @lookup_tuple {:via, Registry, {:mailer_process_registry, :mailer}}

  def send_notification_email(params) do
    GenServer.call(@lookup_tuple, {:send_notification_email, params})
  end

  def send_digest_email(params) do
    GenServer.call(@lookup_tuple, {:send_digest_email, params})
  end
end
