defmodule MbtaServer.AlertProcessor.NotificationSmserTest do
  use ExUnit.Case

  alias MbtaServer.AlertProcessor.NotificationSmser

  test "notification_sms/2" do
    message = "This is a test sms"
    user_phone_number = "5555551234"
    {:ok, sms} = NotificationSmser.notification_sms(message, user_phone_number)
    params = sms.params

    assert params["Message"] == message
    assert params["PhoneNumber"] == user_phone_number
    assert params["Action"] == "Publish"
    assert_received :published_sms
  end
end
