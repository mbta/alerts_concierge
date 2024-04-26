defmodule AlertProcessor.NotificationWorkerTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: false
  import Mock

  alias AlertProcessor.{Model, NotificationWorker, SendingQueue}
  alias Model.{Alert, InformedEntity, Notification}

  @alert %Alert{
    id: "1",
    informed_entities: [
      %InformedEntity{route: "Blue", route_type: 1}
    ]
  }

  @email_notification %Notification{
    header: "This is a test alert",
    service_effect: "effect",
    alert_id: "1",
    email: "test@example.com",
    phone_number: nil,
    send_after: DateTime.utc_now(),
    status: :sent,
    alert: @alert
  }

  @sms_notification %Notification{
    header: "This is a test alert",
    service_effect: "effect",
    alert_id: "1",
    email: nil,
    phone_number: 3,
    send_after: DateTime.utc_now(),
    status: :sent,
    alert: @alert
  }

  test "passes email jobs from sending queue to notification" do
    {:ok, pid} = start_supervised(NotificationWorker)
    :erlang.trace(pid, true, [:receive])

    SendingQueue.push(@email_notification)

    assert_receive {:trace, ^pid, :receive, {:sent_email, _}}
  end

  test "passes sms jobs from sending queue to notification" do
    {:ok, pid} = start_supervised(NotificationWorker)
    :erlang.trace(pid, true, [:receive])

    SendingQueue.push(@sms_notification)
    assert SendingQueue.length() == 1
    assert_receive {:trace, ^pid, :receive, {:publish, _}}
    assert SendingQueue.length() == 0
  end

  test "re-adds notification to queue in case of 400 throttling error" do
    with_mock ExAws.Mock,
      request: fn operation, _ ->
        :timer.sleep(40)
        send(self(), {operation.action, operation.params})
        {:error, {:http_error, 400, %{code: "Throttling", message: "Rate exceeded"}}}
      end do
      {:ok, pid} = start_supervised(NotificationWorker)
      :erlang.trace(pid, true, [:receive])
      assert SendingQueue.length() == 0
      SendingQueue.push(@sms_notification)
      assert SendingQueue.length() == 1
      assert_receive {:trace, ^pid, :receive, {:publish, _}}
    end
  end

  test "does not re-add to queue in case of other error" do
    with_mock ExAws.Mock,
      request: fn operation, _ ->
        :timer.sleep(40)
        send(self(), {operation.action, operation.params})
        {:error, {:other_error, 500, %{}}}
      end do
      {:ok, pid} = start_supervised(NotificationWorker)
      :erlang.trace(pid, true, [:receive])
      assert SendingQueue.length() == 0
      SendingQueue.push(@sms_notification)
      assert SendingQueue.length() == 1
      assert_receive {:trace, ^pid, :receive, {:publish, _}}
      assert SendingQueue.length() == 0
    end
  end
end
