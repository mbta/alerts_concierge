defmodule AlertProcessor.NotificationSmserTest do
  use ExUnit.Case

  alias AlertProcessor.NotificationSmser

  test "notification_sms/2" do
    message = "This is a test sms"
    user_phone_number = "5555551234"
    sms_operation = NotificationSmser.notification_sms(message, user_phone_number)
    params = sms_operation.params

    assert params["Message"] == message
    assert params["PhoneNumber"] == "+1#{user_phone_number}"
    assert params["Action"] == "Publish"
  end
end
