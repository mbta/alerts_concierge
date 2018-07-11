defmodule ConciergeSite.Dissemination.DeliverLaterStrategy do
  @behaviour Bamboo.DeliverLaterStrategy
  require Logger
  alias Bamboo.SMTPAdapter.SMTPError

  def deliver_later(adapter, email, config) do
    Task.async(fn ->
      try do
        result = adapter.deliver(email, config)
        Logger.info(fn -> "Email result: #{inspect(result)}, notification_id: #{email.private.notification_id}" end)
        result
      rescue
        # Consciously dropping the email on the floor if we get an SMTP error.
        # Once we learn more about why we are getting these occasionally we might want to take better action.
        e in SMTPError ->
          Logger.error(fn -> "SMTP error sending to #{email.to}: #{e.message}" end)
      end
    end)
  end
end
