defmodule AlertProcessor.EmailMock do
  @moduledoc "Mock email builder to enable AlertProcessor tests to be run without ConciergeSite"

  def notification_email(%{email: email} = notification) do
    # Return a simple "email" sufficient for testing purposes; MailerMock doesn't care what it is
    %{to: email, notification: notification}
  end
end
