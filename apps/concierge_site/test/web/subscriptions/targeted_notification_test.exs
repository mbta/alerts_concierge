defmodule ConciergeSite.TargetedNotificationTest do
  use ConciergeSite.DataCase
  use ExUnit.Case
  use Bamboo.Test
  alias ConciergeSite.Dissemination.Email
  alias ConciergeSite.TargetedNotification

  describe "send_targeted_notification/1" do
    test "sends email to subscriber if admin selected email toggle" do
      subscriber = insert(:user, email: "test@test.com")

      message = %{"carrier" => "email", "subscriber_email" => subscriber.email,
                  "subject" => "testing", "email_body" => "body of test email"}
      TargetedNotification.send_targeted_notification(message)

      email = Email.targeted_notification_email(subscriber.email, message["subject"], message["email_body"])
      assert_delivered_with(to: [{nil, "test@test.com"}])
      assert email.html_body =~ "body of test email"
    end

    test "sends sms to subscriber if admin selected sms toggle" do
      subscriber = insert(:user, email: "test@test.com", phone_number: "5556667777")

      message = %{"carrier" => "sms", "subscriber_phone_number" => subscriber.phone_number,
                  "subject" => "testing", "sms_body" => "body of test email"}
      TargetedNotification.send_targeted_notification(message)

      assert_received :publish
    end
  end
end
