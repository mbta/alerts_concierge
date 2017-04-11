defmodule MbtaServer.AlertProcessor.MessagerTest do
  use ExUnit.Case
  use Bamboo.Test

  alias MbtaServer.{NotificationMailer}
  alias MbtaServer.AlertProcessor.{Messager, Model.Notification}

  @email "test@example.com"
  @body "This is a test alert"
  @phone_number "+15555551234"

  test "notification_email/1 requires a notification" do
    notification = %Notification{
      message: nil,
      email: @email,
      phone_number: @phone_number
    }

    response = Messager.send_notification(notification)
    assert {:error, _} = response
  end

  test "notification_email/1 requires an email or phone number" do
    notification = %Notification{
      message: @body,
      email: nil,
      phone_number: nil
    }
    response = Messager.send_notification(notification)
    assert {:error, _} = response
  end

  test "notification_email/1 can send sms" do
    notification = %Notification{
      message: @body,
      email: nil,
      phone_number: @phone_number
    }

    {:ok, _} = Messager.send_notification(notification)
    assert_received :published_sms
  end

  test "notification_email/1 can send email" do
    notification = %Notification{
      message: @body,
      email: @email,
      phone_number: nil
    }

    {:ok, _} = Messager.send_notification(notification)
    assert_delivered_email NotificationMailer.notification_email(@body, @email)
  end

  test "notification_email/1 can send sms and email" do
    notification = %Notification{
      message: @body,
      email: @email,
      phone_number: @phone_number
    }
    {:ok, _} = Messager.send_notification(notification)
    assert_delivered_email NotificationMailer.notification_email(@body, @email)
    assert_received :published_sms
  end
end
