defmodule AlertProcessor.DispatcherTest do
  use ExUnit.Case
  use Bamboo.Test

  alias AlertProcessor.{Dispatcher, Model}
  alias Model.{Alert, InformedEntity, Notification}

  @email "test@example.com"
  @body "This is a test alert"
  @phone_number "5555551234"
  @alert %Alert{
    id: "1",
    informed_entities: [
      %InformedEntity{route: "Blue", route_type: 1}
    ]
  }

  test "notification_email/1 requires a header" do
    notification = %Notification{
      header: nil,
      email: @email,
      phone_number: @phone_number
    }

    response = Dispatcher.send_notification(notification)
    assert {:error, _} = response
  end

  test "notification_email/1 requires an email or phone number" do
    notification = %Notification{
      header: @body,
      email: nil,
      phone_number: nil
    }
    response = Dispatcher.send_notification(notification)
    assert {:error, _} = response
  end

  test "notification_email/1 can send sms" do
    notification = %Notification{
      header: @body,
      email: nil,
      phone_number: @phone_number
    }

    {:ok, _} = Dispatcher.send_notification(notification)
    assert_received :publish
  end

  test "notification_email/1 can send email" do
    notification = %Notification{
      header: @body,
      email: @email,
      phone_number: nil,
      alert: @alert
    }

    {:ok, _} = Dispatcher.send_notification(notification)
    assert_received {:sent_notification_email, ^notification}
  end

  test "notification_email/1 cannot send both sms and email" do
    notification = %Notification{
      header: @body,
      email: @email,
      phone_number: @phone_number,
      alert: @alert
    }
    {:ok, _} = Dispatcher.send_notification(notification)
    refute_received {:sent_notification_email, ^notification}
    assert_received :publish
  end
end
