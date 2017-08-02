defmodule ConciergeSite.Dissemination.EmailTest do
  use ConciergeSite.ConnCase
  alias ConciergeSite.Dissemination.Email

  test "password reset email" do
    user = insert(:user)
    password_reset = insert(:password_reset, user: user)

    email = Email.password_reset_email(user, password_reset)

    assert email.to == user.email
    assert email.subject == "Reset Your MBTA Alerts Password"
    assert email.html_body =~ "Please click the link below and follow the instructions on the page to reset your password"
    assert email.html_body =~ "/unsubscribe"
  end

  test "unknown password reset email" do
    email_address = "testing@test.com"
    email = Email.unknown_password_reset_email(email_address)

    assert email.to == email_address
    assert email.subject == "MBTA Alerts Password Reset Attempted"
    assert email.html_body =~ "If you are an MBTA Alerts subscriber and were expecting this email, please try again with the email associated with your account."
  end

  test "confirmation email" do
    user = insert(:user)

    email = Email.confirmation_email(user)

    assert email.to == user.email
    assert email.subject == "MBTA Alerts Account Confirmation"
    assert email.html_body =~ "Congratulations, you have successfully subscribed to receive MBTA email alerts."
    assert email.html_body =~ "/unsubscribe"
    assert email.html_body =~ "/my-account/confirm_disable?token="
  end
end
