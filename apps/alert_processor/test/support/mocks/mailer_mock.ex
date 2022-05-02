defmodule AlertProcessor.MailerMock do
  @moduledoc "Mock mailer to enable AlertProcessor tests to be run without ConciergeSite"

  def deliver_now(email, _options \\ [])

  def deliver_now(%{to: "mailer_error" <> _}, _), do: {:error, %{message: "error requested"}}

  def deliver_now(email, _) do
    send(self(), {:sent_email, email})
    {:ok, nil, nil}
  end
end
