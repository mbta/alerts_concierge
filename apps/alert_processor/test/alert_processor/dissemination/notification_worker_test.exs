defmodule AlertProcessor.NotificationWorkerTest do
  use AlertProcessor.DataCase
  use Bamboo.Test, shared: true

  alias AlertProcessor.{Model, NotificationWorker, SendingQueue}
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

    {:ok, notification: notification, notification_2: notification_2}
  end

  test "Worker passes jobs from sending queue to notificationr", %{notification: notification} do
    SendingQueue.start_link()
    {:ok, pid} = NotificationWorker.start_link([name: :notification_worker_test])
    :erlang.trace(pid, true, [:receive])

    SendingQueue.enqueue(notification)
    :timer.sleep(101)
    assert_received {:trace, ^pid, :receive, {:sent_notification_email, ^notification}}
  end

  test "Worker runs on interval jobs from sending queue to notification", %{notification: notification, notification_2: notification_2} do
    SendingQueue.start_link()
    {:ok, pid} = NotificationWorker.start_link([name: :notification_worker_interval_test])
    :erlang.trace(pid, true, [:receive])
    SendingQueue.enqueue(notification)
    :timer.sleep(101)
    assert_received {:trace, ^pid, :receive, {:sent_notification_email, ^notification}}
    assert SendingQueue.pop == :error
    SendingQueue.enqueue(notification_2)
    :timer.sleep(101)
    assert_received {:trace, ^pid, :receive, {:sent_notification_email, ^notification_2}}
  end
end
