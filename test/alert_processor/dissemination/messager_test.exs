defmodule MbtaServer.AlertProcessor.MessagerTest do
  use ExUnit.Case
  use Bamboo.Test

  alias MbtaServer.{AlertMessageMailer}
  alias MbtaServer.AlertProcessor.{Messager}

  test "alert_message_email/1 requires a message" do
    message = nil
    user_email = "test@example.com"
    user_phone_number = "+15555551234"
    message_params = {message, user_email, user_phone_number}
    response = Messager.send_alert_message(message_params)
    assert {:error, _} = response
  end

  test "alert_message_email/1 requires an email or phone number" do
    message = "This is a test message"
    user_email = nil
    user_phone_number = nil
    message_params = {message, user_email, user_phone_number}
    response = Messager.send_alert_message(message_params)
    assert {:error, _} = response
  end

  test "alert_message_email/1 can send sms" do
    message = "This is a test message"
    user_email = nil
    user_phone_number = "+15555551234"
    message_params = {message, user_email, user_phone_number}
    {:ok, _} = Messager.send_alert_message(message_params)
    assert_received :published_sms
  end

  test "alert_message_email/1 can send email" do
    message = "This is a test message"
    user_email = "test@example.com"
    user_phone_number = nil
    message_params = {message, user_email, user_phone_number}
    {:ok, _} = Messager.send_alert_message(message_params)
    assert_delivered_email AlertMessageMailer.alert_message_email(message, user_email)
  end

  test "alert_message_email/1 can send sms and email" do
    message = "This is a test email"
    user_email = "test@example.com"
    user_phone_number = "+15555551234"
    message_params = {message, user_email, user_phone_number}
    {:ok, _} = Messager.send_alert_message(message_params)
    assert_delivered_email AlertMessageMailer.alert_message_email(message, user_email)
    assert_received :published_sms
  end
end
