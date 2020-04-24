defmodule ConciergeSite.Dissemination.EmailTest do
  @moduledoc false
  use ConciergeSite.ConnCase
  alias ConciergeSite.Dissemination.Email

  test "password reset email" do
    user = insert(:user)
    reset_token = "some reset token"

    email = Email.password_reset_email(user, reset_token)

    assert email.to == user.email
    assert email.subject == "Reset your T-Alerts password"
    assert email.html_body =~ "You recently requested a password reset for your T-Alerts account"
  end

  test "confirmation email" do
    user = insert(:user)

    email = Email.confirmation_email(user)

    assert email.to == user.email
    assert email.subject == "Welcome to T-Alerts"
    assert email.html_body =~ "Thanks for signing up for T-Alerts!"
    assert email.html_body =~ "mbtafeedback.com"
  end
end
