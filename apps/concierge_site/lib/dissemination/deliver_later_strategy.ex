defmodule ConciergeSite.Dissemination.DeliverLaterStrategy do
  @moduledoc """
  Bamboo strategy for delivering asynchronously
  """
  @behaviour Bamboo.DeliverLaterStrategy
  require Logger
  alias Bamboo.SMTPAdapter.SMTPError

  def deliver_later(adapter, email, config) do
    Task.async(fn ->
      try do
        result = adapter.deliver(email, config)

        Logger.info(fn ->
          "Email result: #{inspect(result)}, notification_id: #{email.private[:notification_id]}"
        end)

        result
      rescue
        # Consciously dropping the email on the floor if we get an SMTP error.
        # Once we learn more about why we are getting these occasionally we might want to take better action.
        e in SMTPError ->
          Logger.error(fn -> "SMTP error sending to #{email_address(email.to)}: #{e.message}" end)

        e ->
          Logger.error(fn ->
            "Unknown error sending to #{email_address(email.to)}: #{inspect(e)}"
          end)
      end
    end)
  end

  defp email_address(email) when is_list(email), do: email |> List.first() |> email_address()

  defp email_address({_, email}), do: email

  defp email_address(email), do: email
end
