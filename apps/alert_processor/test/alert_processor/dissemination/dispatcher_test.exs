defmodule AlertProcessor.DispatcherTest do
  use ExUnit.Case
  use Bamboo.Test

  alias AlertProcessor.{Dispatcher, Model.Notification, NotificationMailer}

  @email "test@example.com"
  @body "This is a test alert"
  @phone_number "5555551234"

  test "notification_email/1 requires a notification" do
    notification = %Notification{
      message: nil,
      email: @email,
      phone_number: @phone_number
    }

    response = Dispatcher.send_notification(notification)
    assert {:error, _} = response
  end

  test "notification_email/1 requires an email or phone number" do
    notification = %Notification{
      message: @body,
      email: nil,
      phone_number: nil
    }
    response = Dispatcher.send_notification(notification)
    assert {:error, _} = response
  end

  test "notification_email/1 can send sms" do
    notification = %Notification{
      message: @body,
      email: nil,
      phone_number: @phone_number
    }

    {:ok, _} = Dispatcher.send_notification(notification)
    assert_received :publish
  end

  test "notification_email/1 can send email" do
    notification = %Notification{
      message: @body,
      email: @email,
      phone_number: nil
    }

    {:ok, _} = Dispatcher.send_notification(notification)
    assert_delivered_email NotificationMailer.notification_email(@body, @email)
  end

  test "notification_email/1 cannot send both sms and email" do
    notification = %Notification{
      message: @body,
      email: @email,
      phone_number: @phone_number
    }
    {:ok, _} = Dispatcher.send_notification(notification)
    refute_delivered_email NotificationMailer.notification_email(@body, @email)
    assert_received :publish
  end
end
