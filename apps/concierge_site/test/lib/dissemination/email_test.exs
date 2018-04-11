defmodule ConciergeSite.Dissemination.EmailTest do
  use ConciergeSite.ConnCase
  alias ConciergeSite.Dissemination.Email

  test "confirmation email" do
    user = insert(:user)

    email = Email.confirmation_email(user)

    assert email.to == user.email
    assert email.subject == "MBTA Alerts Account Confirmation"
    assert email.html_body =~ "Congratulations, you have successfully subscribed to receive T-Alerts."
    assert email.html_body =~ "mbtafeedback.com"
  end

  test "send targeted notification email" do
    subscriber = insert(:user, email: "testing@test.com")
    subject = "Test Subject"
    body = "This is the body of the test email"

    email = Email.targeted_notification_email(subscriber, subject, body)

    assert email.to == subscriber.email
    assert email.subject == subject
    assert email.html_body =~ body
    assert email.html_body =~ "mbtafeedback.com"
  end

  test "from email contains name" do
    subscriber = insert(:user, email: "testing@test.com")
    subject = "Test Subject"
    body = "This is the body of the test email"

    email = Email.targeted_notification_email(subscriber, subject, body)

    assert email.from == {"T-Alert", "alert@mbta.com"}
  end
end
