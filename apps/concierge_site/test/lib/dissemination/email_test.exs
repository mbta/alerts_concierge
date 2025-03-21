defmodule ConciergeSite.Dissemination.EmailTest do
  @moduledoc false
  use ConciergeSite.ConnCase
  alias ConciergeSite.Dissemination.Email

  test "confirmation email" do
    user = insert(:user)

    email = Email.confirmation_email(user)

    assert email.to == user.email
    assert email.subject == "Welcome to T-Alerts"
    assert email.html_body =~ "Thanks for signing up for T-Alerts!"
    assert email.html_body =~ "mbta.com/customer-support"
    assert email.headers["List-Unsubscribe-Post"] == "List-Unsubscribe=One-Click"

    assert email.headers["List-Unsubscribe"]
           |> String.match?(~r(https:\/\/alerts.localhost\/unsubscribe\/\S{100,}))
  end
end
