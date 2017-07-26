defmodule AlertProcessor.DigestDispatcher do
  @moduledoc """
  Sends digests to users
  """
  alias AlertProcessor.{DigestMailer, MailHelper, Model}
  alias Model.DigestMessage

  @doc """
  Takes a list of digests and dispatches an email for each one
  """
  @spec send_emails([DigestMessage.t]) :: :ok
  def send_emails(digest_messages) do
    Enum.each(digest_messages, &send_email/1)
  end

  defp send_email(digest_message) do
    unsubscribe_url = MailHelper.unsubscribe_url(digest_message.user)
    digest_message
    |> DigestMailer.digest_email(unsubscribe_url)
    |> DigestMailer.deliver_later
   end
end
