defmodule MbtaServer.AlertProcessor.MessagerTest do
  use ExUnit.Case
  use Bamboo.Test

  alias MbtaServer.{AlertMessageMailer}
  alias MbtaServer.AlertProcessor.{Messager, Model.AlertMessage}

  @email "test@example.com"
  @body "This is a test alert"
  @phone_number "+15555551234"

  test "alert_message_email/1 requires a message" do
    message = %AlertMessage{
      message: nil,
      email: @email,
      phone_number: @phone_number
    }

    response = Messager.send_alert_message(message)
    assert {:error, _} = response
  end

  test "alert_message_email/1 requires an email or phone number" do
    message = %AlertMessage{
      message: @body,
      email: nil,
      phone_number: nil
    }
    response = Messager.send_alert_message(message)
    assert {:error, _} = response
  end

  test "alert_message_email/1 can send sms" do
    message = %AlertMessage{
      message: @body,
      email: nil,
      phone_number: @phone_number
    }

    {:ok, _} = Messager.send_alert_message(message)
    assert_received :published_sms
  end

  test "alert_message_email/1 can send email" do
    message = %AlertMessage{
      message: @body,
      email: @email,
      phone_number: nil
    }

    {:ok, _} = Messager.send_alert_message(message)
    assert_delivered_email AlertMessageMailer.alert_message_email(@body, @email)
  end

  test "alert_message_email/1 can send sms and email" do
    message = %AlertMessage{
      message: @body,
      email: @email,
      phone_number: @phone_number
    }
    {:ok, _} = Messager.send_alert_message(message)
    assert_delivered_email AlertMessageMailer.alert_message_email(@body, @email)
    assert_received :published_sms
  end
end
