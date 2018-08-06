defmodule AlertProcessor.NotificationWorkerTest do
  use AlertProcessor.DataCase
  use Bamboo.Test, shared: true

  alias AlertProcessor.{Model, NotificationWorker, SendingQueue}
  alias Model.{Alert, InformedEntity, Notification}
  import AlertProcessor.Factory

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
    effect = "effect"
    status = "unsent"

    notification = %Notification{
      header: body,
      service_effect: effect,
      alert_id: "1",
      email: email,
      phone_number: nil,
      send_after: DateTime.utc_now(),
      status: status,
      alert: @alert
    }

    notification_2 = %Notification{
      header: body_2,
      service_effect: effect,
      alert_id: "1",
      email: email,
      phone_number: nil,
      send_after: DateTime.utc_now(),
      status: status,
      alert: @alert
    }

    notification_3 = %Notification{
      header: body,
      service_effect: effect,
      alert_id: "1",
      email: email,
      phone_number: nil,
      send_after: DateTime.utc_now(),
      status: status,
      alert: @alert
    }

    {:ok,
     notification: notification, notification_2: notification_2, notification_3: notification_3}
  end

  test "Worker passes jobs from sending queue to notification", %{notification: notification} do
    user = insert(:user)
    notification = Map.put(notification, :user, user)

    {:ok, pid} = start_supervised(NotificationWorker)
    :erlang.trace(pid, true, [:receive])

    SendingQueue.enqueue(notification)

    assert_receive {:trace, ^pid, :receive, {:sent_notification_email, _}}
  end
end
