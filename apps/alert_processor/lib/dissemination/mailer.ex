defmodule AlertProcessor.Dissemination.Mailer do
  @moduledoc """
  interface for sending emails from alert processor app
  """

  def send_notification_email(name \\ :mailer, params) do
    GenServer.call(to_tuple(name), {:send_notification_email, params})
  end

  defp to_tuple(name) do
    {:via, Registry, {:mailer_process_registry, name}}
  end
end
