defmodule AlertProcessor.NotificationSmserTest do
  use ExUnit.Case

  alias AlertProcessor.{Model.Notification, NotificationSmser}

  @phone_number "5555551234"
  @message "This is a test sms"

  test "notification_sms/2" do
    notification = %Notification{
      header: @message,
      email: nil,
      phone_number: @phone_number,
      closed_timestamp: nil
    }

    sms_operation = NotificationSmser.notification_sms(notification)
    params = sms_operation.params

    assert params["Message"] == @message
    assert params["PhoneNumber"] == "+1#{@phone_number}"
    assert params["Action"] == "Publish"
  end

  test "notification_sms/2 with a closed alert" do
    notification = %Notification{
      header: @message,
      email: nil,
      phone_number: @phone_number,
      closed_timestamp: DateTime.utc_now(),
      type: :all_clear
    }
    sms_operation = NotificationSmser.notification_sms(notification)
    assert sms_operation.params["Message"] == "All clear (re: This is a test sms)"
  end

  test "notification_sms/2 with an updated alert" do
    notification = %Notification{
      header: @message,
      email: nil,
      phone_number: @phone_number,
      closed_timestamp: DateTime.utc_now(),
      type: :update
    }
    sms_operation = NotificationSmser.notification_sms(notification)
    assert sms_operation.params["Message"] == "Update (re: This is a test sms)"
  end

  test "notification_sms/2 with a reminder alert" do
    notification = %Notification{
      header: @message,
      email: nil,
      phone_number: @phone_number,
      closed_timestamp: DateTime.utc_now(),
      type: :reminder
    }
    sms_operation = NotificationSmser.notification_sms(notification)
    assert sms_operation.params["Message"] == "Reminder (re: This is a test sms)"
  end
end
