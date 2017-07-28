defmodule AlertProcessor.DigestDispatcher do
  @moduledoc """
  Sends digests to users
  """
  @mailer Application.get_env(:alert_processor, :mailer)
  alias AlertProcessor.Model.DigestMessage

  @doc """
  Takes a list of digests and dispatches an email for each one
  """
  @spec send_emails([DigestMessage.t]) :: :ok
  def send_emails(digest_messages) do
    Enum.each(digest_messages, &@mailer.send_digest_email/1)
  end
end
