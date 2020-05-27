defmodule AlertProcessor.MailerMock do
  @moduledoc "Mock mailer to enable AlertProcessor tests to be run without ConciergeSite"

  def deliver_now(email, _options \\ [])

  def deliver_now(%{to: "bad_email"}, _) do
    raise ArgumentError, message: "invalid email"
  end

  def deliver_now(%{to: "raise_error" <> _}, _) do
    raise Application.fetch_env!(:alert_processor, :mailer_error), message: "error requested"
  end

  def deliver_now(email, _) do
    send(self(), {:sent_email, email})
  end
end
