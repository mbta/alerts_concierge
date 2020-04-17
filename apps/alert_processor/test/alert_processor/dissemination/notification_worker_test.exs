defmodule AlertProcessor.NotificationWorkerTest do
  @moduledoc false
  use AlertProcessor.DataCase

  alias AlertProcessor.{Model, NotificationWorker, SendingQueue}
  alias Model.{Alert, InformedEntity, Notification}

  @alert %Alert{
    id: "1",
    informed_entities: [
      %InformedEntity{route: "Blue", route_type: 1}
    ]
  }

  @notification %Notification{
    header: "This is a test alert",
    service_effect: "effect",
    alert_id: "1",
    email: "test@example.com",
    phone_number: nil,
    send_after: DateTime.utc_now(),
    status: :sent,
    alert: @alert
  }

  test "passes jobs from sending queue to notification" do
    {:ok, pid} = start_supervised(NotificationWorker)
    :erlang.trace(pid, true, [:receive])

    SendingQueue.enqueue(@notification)

    assert_receive {:trace, ^pid, :receive, {:sent_email, _}}
  end
end
