defmodule AlertProcessor.DigestDispatcher do
  @moduledoc """
  Sends digests to users
  """
  alias AlertProcessor.{DigestMailer, Model}
  alias Model.Digest

  @doc """
  Takes a list of digests and dispatches an email for each one
  """
  @spec send_emails([Digest.t]) :: :ok
  def send_emails(digests) do
    digests
    |> Enum.each(fn(digest) ->
      send_email(digest)
    end)
    :ok
  end

  defp send_email(digest) do
    digest
    |> DigestMailer.digest_email()
    |> DigestMailer.deliver_later
   end
end
