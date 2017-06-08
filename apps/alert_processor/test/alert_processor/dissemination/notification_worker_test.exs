defmodule AlertProcessor.NotificationWorkerTest do
  use AlertProcessor.DataCase
  use Bamboo.Test, shared: true

  alias AlertProcessor.{Model, NotificationMailer, NotificationWorker, SendingQueue}
  alias Model.{Alert, InformedEntity, Notification}

  @alert %Alert{
    id: "1",
    informed_entities: [
      %InformedEntity{route: "Blue", route_type: 1}
    ]
  }

  setup_all do
    email = "test@example.com"
    body = "This is a test alert"
    body_2 = "Another alert"
    status = "unsent"

    notification = %Notification{
      header: body,
      email: email,
      phone_number: nil,
      send_after: DateTime.utc_now(),
      status: status,
      alert: @alert
    }

    notification_2 = %Notification{
      header: body_2,
      email: email,
      phone_number: nil,
      send_after: DateTime.utc_now(),
      status: status,
      alert: @alert
    }

    {:ok, notification: notification, notification_2: notification_2, email: email}
  end

  test "Worker passes jobs from sending queue to notificationr", %{notification: notification,  email: email} do
    SendingQueue.start_link()
    NotificationWorker.start_link([])
    SendingQueue.enqueue(notification)

    assert_delivered_email NotificationMailer.notification_email(notification, email)
  end

  test "Worker runs on interval jobs from sending queue to notification", %{notification: notification, notification_2: notification_2, email: email} do
    SendingQueue.start_link()
    NotificationWorker.start_link([])
    SendingQueue.enqueue(notification)

    assert_delivered_email NotificationMailer.notification_email(notification, email)
    assert SendingQueue.pop == :error

    SendingQueue.enqueue(notification_2)
    :timer.sleep(101)

    assert_delivered_email NotificationMailer.notification_email(notification_2, email)
  end
end
