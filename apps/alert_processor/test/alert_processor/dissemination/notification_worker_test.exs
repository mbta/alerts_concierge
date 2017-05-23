defmodule AlertProcessor.NotificationWorkerTest do
  use AlertProcessor.DataCase
  use Bamboo.Test, shared: true

  alias AlertProcessor.{Model.Notification, NotificationMailer, NotificationWorker, SendingQueue}

  setup_all do
    email = "test@example.com"
    body = "This is a test alert"
    body_2 = "Another alert"
    phone_number = "+15555551234"
    status = "unsent"

    notification = %Notification{
      message: body,
      email: email,
      phone_number: phone_number,
      send_after: DateTime.utc_now(),
      status: status
    }

    notification_2 = %Notification{
      message: body_2,
      email: email,
      phone_number: phone_number,
      send_after: DateTime.utc_now(),
      status: status
    }

    {:ok, notification: notification, notification_2: notification_2, email: email, body: body, body_2: body_2}
  end

  test "Worker passes jobs from sending queue to notificationr", %{notification: notification, body: body, email: email} do
    SendingQueue.start_link()
    NotificationWorker.start_link([])
    SendingQueue.enqueue(notification)

    assert_delivered_email NotificationMailer.notification_email(body, email)
  end

  test "Worker runs on interval jobs from sending queue to notificationr", %{notification: notification, notification_2: notification_2, body: body, body_2: body_2, email: email} do
    SendingQueue.start_link()
    NotificationWorker.start_link([])
    SendingQueue.enqueue(notification)

    assert_delivered_email NotificationMailer.notification_email(body, email)
    assert SendingQueue.pop == :error

    SendingQueue.enqueue(notification_2)
    :timer.sleep(101)

    assert_delivered_email NotificationMailer.notification_email(body_2, email)
  end
end
