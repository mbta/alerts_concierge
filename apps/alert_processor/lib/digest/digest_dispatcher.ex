defmodule AlertProcessor.DigestDispatcher do
  @moduledoc """
  Sends digests to users
  """
  @mailer Application.get_env(:alert_processor, :mailer)
  alias AlertProcessor.{Helpers.ConfigHelper, Model.DigestMessage}

  @doc """
  Takes a list of digests and dispatches an email for each one
  """
  @spec send_emails([DigestMessage.t]) :: :ok
  def send_emails(digest_messages) do
    Enum.each(digest_messages, fn(digest_message) ->
      :timer.sleep(send_rate())
      @mailer.send_digest_email(digest_message)
    end)
  end

  defp send_rate do
    ConfigHelper.get_int(:send_rate)
  end
end
