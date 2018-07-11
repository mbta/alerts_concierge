defmodule ConciergeSite.Dissemination.DeliverLaterStrategy do
  @behaviour Bamboo.DeliverLaterStrategy
  require Logger
  alias Bamboo.SMTPAdapter.SMTPError

  def deliver_later(adapter, email, config) do
    Task.async(fn ->
      try do
        result = adapter.deliver(email, config)
        info = "Email result: #{inspect(result)}"
        info = if Map.has_key?(email, :private) and Map.has_key?(email.private, :notification_id) do
          info <> ", notification_id: #{email.private.notification_id}"
        else
          info
        end
        Logger.info(info)
        result
      rescue
        # Consciously dropping the email on the floor if we get an SMTP error.
        # Once we learn more about why we are getting these occasionally we might want to take better action.
        e in SMTPError ->
          Logger.error(fn -> "SMTP error sending to #{email.to}: #{e.message}" end)
        e ->
          Logger.error(fn -> "Unknown error sending to #{email.to}: #{inspect(e)}" end)
      end
    end)
  end
end
