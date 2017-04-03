defmodule MbtaServer.AlertProcessor.AlertMessageSmserTest do
  use ExUnit.Case

  alias MbtaServer.AlertProcessor.AlertMessageSmser

  test "alert_message_sms/2" do
    message = "This is a test sms"
    user_phone_number = "5555551234"
    {:ok, sms} = AlertMessageSmser.alert_message_sms(message, user_phone_number)
    params = sms.params

    assert params["Message"] == message
    assert params["PhoneNumber"] == user_phone_number
    assert params["Action"] == "Publish"
    assert_received :published_sms
  end
end
