defmodule MbtaServer.NotificationMailerTest do
  use ExUnit.Case
  use Bamboo.Test

  alias MbtaServer.NotificationMailer

  test "notification_email/1" do
    message = "This is a test email"
    user_email = "test@example.com"
    email = NotificationMailer.notification_email(message, user_email)

    assert email.to == user_email
    assert email.from == "faizaan@intrepid.io"
    assert email.subject == "Test Email"
    assert email.html_body =~ "Test Email"
    assert email.html_body =~ "This is a test email"
  end
end
