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
      closed_timestamp: DateTime.utc_now()
    }

    sms_operation = NotificationSmser.notification_sms(notification)
    params = sms_operation.params

    assert params["Message"] == "All clear (re: This is a test sms)"
    assert params["PhoneNumber"] == "+1#{@phone_number}"
    assert params["Action"] == "Publish"
  end
end
