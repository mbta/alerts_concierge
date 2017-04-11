defmodule MbtaServer.AlertProcessor.DispatcherTest do
  use MbtaServer.DataCase
  use Bamboo.Test
  import MbtaServer.Factory

  alias MbtaServer.{NotificationMailer, Repo}
  alias MbtaServer.AlertProcessor.{Dispatcher, Model.Notification}

  @email "test@example.com"
  @body "This is a test alert"
  @phone_number "+15555551234"

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
    assert_received :published_sms
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

  test "notification_email/1 can send sms and email" do
    notification = %Notification{
      message: @body,
      email: @email,
      phone_number: @phone_number
    }
    {:ok, _} = Dispatcher.send_notification(notification)
    assert_delivered_email NotificationMailer.notification_email(@body, @email)
    assert_received :published_sms
  end

  test "send_notification/1 persists Notification" do
    user = insert(:user)
    notification = %Notification{
      message: @body,
      phone_number: @phone_number,
      user_id: user.id,
      alert_id: "123"
    }

    {:ok, _} = Dispatcher.send_notification(notification)

    saved_notification = Repo.one(Notification)

    assert %Notification{} = saved_notification
    assert saved_notification.user_id == user.id
    assert saved_notification.message == @body
    assert saved_notification.phone_number == @phone_number
  end
end
