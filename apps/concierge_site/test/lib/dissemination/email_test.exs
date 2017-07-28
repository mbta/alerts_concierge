defmodule ConciergeSite.Dissemination.EmailTest do
  use ConciergeSite.ConnCase
  alias ConciergeSite.Dissemination.Email

  test "password reset email" do
    password_reset = insert(:password_reset)
    email_address = "testemail@example.com"

    email = Email.password_reset_html_email(email_address, password_reset.id)

    assert email.to == email_address
    assert email.subject == "Reset Your MBTA Alerts Password"
    assert email.html_body =~ "Please click the link below and follow the instructions on the page to reset your password"
  end
end
