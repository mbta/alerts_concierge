defmodule MbtaServer.AlertProcessor.MessagerTest do
  use ExUnit.Case
  use Bamboo.Test

  alias MbtaServer.{AlertMessageMailer}
  alias MbtaServer.AlertProcessor.{Messager, Model.AlertMessage}

  setup do
    email = "test@example.com"
    body = "This is a test alert"
    phone_number = "+15555551234"

    {:ok, email: email, body: body, phone_number: phone_number}
  end

  test "alert_message_email/1 requires a message", %{email: email, phone_number: phone_number} do
    message = %AlertMessage{
      message: nil,
      email: email,
      phone_number: phone_number
    }

    response = Messager.send_alert_message(message)
    assert {:error, _} = response
  end

  test "alert_message_email/1 requires an email or phone number", %{body: body} do
    message = %AlertMessage{
      message: body,
      email: nil,
      phone_number: nil
    }
    response = Messager.send_alert_message(message)
    assert {:error, _} = response
  end

  test "alert_message_email/1 can send sms", %{phone_number: phone_number, body: body} do
    message = %AlertMessage{
      message: body,
      email: nil,
      phone_number: phone_number
    }

    {:ok, _} = Messager.send_alert_message(message)
    assert_received :published_sms
  end

  test "alert_message_email/1 can send email", %{email: email, body: body} do
    message = %AlertMessage{
      message: body,
      email: email,
      phone_number: nil
    }

    {:ok, _} = Messager.send_alert_message(message)
    assert_delivered_email AlertMessageMailer.alert_message_email(body, email)
  end

  test "alert_message_email/1 can send sms and email", %{email: email, body: body, phone_number: phone_number} do
    message = %AlertMessage{
      message: body,
      email: email,
      phone_number: phone_number
    }
    {:ok, _} = Messager.send_alert_message(message)
    assert_delivered_email AlertMessageMailer.alert_message_email(body, email)
    assert_received :published_sms
  end
end
