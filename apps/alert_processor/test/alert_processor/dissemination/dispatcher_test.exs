defmodule AlertProcessor.DispatcherTest do
  @moduledoc false
  use ExUnit.Case
  use Bamboo.Test

  alias AlertProcessor.{Dispatcher, Model}
  alias Model.{Alert, InformedEntity, Notification}

  @email "test@example.com"
  @header "This is a test alert"
  @phone_number "5555551234"
  @alert %Alert{
    id: "1",
    informed_entities: [
      %InformedEntity{route: "Blue", route_type: 1}
    ]
  }

  test "can send SMS" do
    notification = %Notification{
      header: @header,
      email: nil,
      phone_number: @phone_number
    }

    {:ok, _} = Dispatcher.send_notification(notification)
    assert_received :publish
  end

  test "can send email" do
    notification = %Notification{
      header: @header,
      email: @email,
      phone_number: nil,
      alert: @alert
    }

    {:ok, _} = Dispatcher.send_notification(notification)
    assert_received {:sent_notification_email, ^notification}
  end

  test "sends SMS and not email when both are possible" do
    notification = %Notification{
      header: @header,
      email: @email,
      phone_number: @phone_number,
      alert: @alert
    }

    {:ok, _} = Dispatcher.send_notification(notification)
    refute_received {:sent_notification_email, ^notification}
    assert_received :publish
  end
end
