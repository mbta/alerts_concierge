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
end
