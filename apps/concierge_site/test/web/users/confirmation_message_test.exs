defmodule ConciergeSite.ConfirmationMessageTest do
  use ConciergeSite.ConnCase
  use Bamboo.Test
  import AlertProcessor.Factory
  alias ConciergeSite.Dissemination.Email
  alias ConciergeSite.ConfirmationMessage

  describe "send_confirmation/1" do
    test "sends email to user without phone number" do
      user = insert(:user, email: "test@test.com", phone_number: nil)

      ConfirmationMessage.send_confirmation(user)

      email = Email.confirmation_email(user)
      refute_received :publish
      assert_delivered_with(to: [{nil, "test@test.com"}])
      assert email.html_body =~ "Congratulations, you have successfully subscribed to receive MBTA email alerts"
    end

    test "sends SMS to user with phone number" do
      user = insert(:user, email: "test@test.com", phone_number: "5556667777")

      ConfirmationMessage.send_confirmation(user)

      assert_received :publish
      assert_delivered_with(to: [{nil, "test@test.com"}])
    end
  end
end
