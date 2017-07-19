defmodule ConciergeSite.ConfirmationMessageTest do
  use ExUnit.Case
  use Bamboo.Test
  alias ConciergeSite.{ConfirmationMessage, Email}

  describe "send_confirmation/1" do
    test "sends email to user without phone number" do
      user = %{
        email: "test@test.com",
        phone_number: nil
      }

      ConfirmationMessage.send_confirmation(user)

      email = Email.confirmation_email(user.email)
      refute_received :publish
      assert_delivered_email email
      assert email.html_body =~ "Thanks for signing up for MBTA Alerts"
    end

    test "sends SMS to user with phone number" do
      user = %{
        email: "test@test.com",
        phone_number: "5556667777"
      }
      ConfirmationMessage.send_confirmation(user)

      assert_received :publish
      refute_delivered_email Email.confirmation_email(user.email)
    end
  end
end
