defmodule AlertProcessor.NotificationSmserTest do
  use ExUnit.Case

  alias AlertProcessor.{Model.Notification, NotificationSmser}

  @phone_number "5555551234"
  @message "This is a test sms"

  test "notification_sms/2" do
    notification = %Notification{
      header: @message,
      email: nil,
      phone_number: @phone_number
    }

    sms_operation = NotificationSmser.notification_sms(notification, @phone_number)
    params = sms_operation.params

    assert params["Message"] == @message
    assert params["PhoneNumber"] == "+1#{@phone_number}"
    assert params["Action"] == "Publish"
  end
end
