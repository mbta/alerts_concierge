defmodule AlertProcessor.DigestDispatcher do
  @moduledoc """
  Sends digests to users
  """
  alias AlertProcessor.{DigestMailer, Model}
  alias Model.DigestMessage

  @doc """
  Takes a list of digests and dispatches an email for each one
  """
  @spec send_emails([DigestMessage.t]) :: :ok
  def send_emails(digest_messages) do
    Enum.each(digest_messages, &send_email/1)
  end

  defp send_email(digest_message) do
    digest_message
    |> DigestMailer.digest_email()
    |> DigestMailer.deliver_later
   end
end
