defmodule AlertProcessor.MailerMock do
  @moduledoc """
  mock mailer implementation to avoid calling to
  concierge site application during tests
  """
  def send_notification_email(notification) do
    send self(), {:sent_notification_email, notification}
    {:ok, %{}}
  end
end
