defmodule ConciergeSite.ConfirmationMessageTest do
  @moduledoc false
  use ConciergeSite.DataCase
  use Bamboo.Test
  alias ConciergeSite.Dissemination.Email
  alias ConciergeSite.ConfirmationMessage

  describe "send_email_confirmation/1" do
    test "sends email to user" do
      user = insert(:user, communication_mode: "email", email: "test@test.com", phone_number: nil)

      ConfirmationMessage.send_email_confirmation(user)

      email = Email.confirmation_email(user)
      refute_received :publish
      assert_email_delivered_with(to: [{nil, "test@test.com"}])
      assert email.html_body =~ "Thanks for signing up for T-Alerts!"
    end
  end

  describe "send_sms_confirmation/1" do
    test "sends SMS to user with phone number" do
      user =
        insert(:user,
          communication_mode: "sms",
          email: "test@test.com",
          phone_number: "5556667777"
        )

      expected = %{body: %{message_id: "123", request_id: "345"}}
      {:ok, actual} = ConfirmationMessage.send_sms_confirmation(user.phone_number, "true")

      assert actual == expected
    end

    test "does not send SMS to user with phone number but no opt-in" do
      user =
        insert(:user,
          communication_mode: "email",
          email: "test@test.com",
          phone_number: "5556667777"
        )

      {:ok, actual} = ConfirmationMessage.send_sms_confirmation(user.phone_number, "false")

      assert actual == nil
    end

    test "does not send SMS to user with empty phone number" do
      user = insert(:user, communication_mode: "email", email: "test@test.com", phone_number: "")

      {:ok, actual} = ConfirmationMessage.send_sms_confirmation(user.phone_number, "true")

      assert actual == nil
    end
  end
end
