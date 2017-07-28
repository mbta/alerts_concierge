defmodule AlertProcessor.MailerMock do
  @moduledoc """
  mock mailer implementation to avoid calling to
  concierge site application during tests
  """
  def send_notification_email(notification) do
    send self(), {:sent_notification_email, notification}
    {:ok, %{}}
  end

  def send_digest_email(digest_message) do
    send self(), {:sent_digest_email, digest_message}
    {:ok, %{}}
  end
end
