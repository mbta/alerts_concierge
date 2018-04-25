defmodule ConciergeSite.ConfirmationMessageTest do
  use ConciergeSite.DataCase
  use Bamboo.Test
  alias ConciergeSite.Dissemination.Email
  alias ConciergeSite.ConfirmationMessage

  describe "send_confirmation/1" do
    test "sends email to user without phone number" do
      user = insert(:user, email: "test@test.com", phone_number: nil)

      ConfirmationMessage.send_confirmation(user)

      email = Email.confirmation_email(user)
      refute_received :publish
      assert_delivered_with(to: [{nil, "test@test.com"}])
      assert email.html_body =~ "Thanks for signing up for T-Alerts Beta!"
    end

    test "sends SMS and email to user with phone number" do
      user = insert(:user, email: "test@test.com", phone_number: "5556667777")

      ConfirmationMessage.send_confirmation(user)

      assert_received :publish
      assert_delivered_with(to: [{nil, "test@test.com"}])
    end
  end
end
