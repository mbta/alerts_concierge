defmodule ConciergeSite.TargetedNotificationTest do
  use ConciergeSite.DataCase
  use ExUnit.Case
  use Bamboo.Test
  alias ConciergeSite.Dissemination.Email
  alias ConciergeSite.TargetedNotification

  describe "send_targeted_notification/2" do
    test "sends email to subscriber if admin selected email toggle" do
      subscriber = insert(:user, email: "test@test.com")

      message = %{"carrier" => "email",
                  "subject" => "testing", "email_body" => "body of test email"}
      TargetedNotification.send_targeted_notification(subscriber, message)

      email = Email.targeted_notification_email(subscriber, message["subject"], message["email_body"])
      assert_delivered_with(to: [{nil, "test@test.com"}])
      assert email.html_body =~ "body of test email"
    end

    test "sends sms to subscriber if admin selected sms toggle" do
      subscriber = insert(:user, email: "test@test.com", phone_number: "5556667777")

      message = %{"carrier" => "sms",
                  "subject" => "testing", "sms_body" => "body of test email"}
      TargetedNotification.send_targeted_notification(subscriber, message)

      assert_received :publish
    end
  end
end
