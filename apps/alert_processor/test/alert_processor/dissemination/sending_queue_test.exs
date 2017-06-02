defmodule AlertProcessor.SendingQueueTest do
  use ExUnit.Case
  alias AlertProcessor.{SendingQueue, Model.Notification}

  setup_all do
    {:ok, notification: %Notification{send_after: DateTime.utc_now()}}
  end

  test "Instantiates empty queue by default", %{test: test} do
    SendingQueue.start_link([name: test])
    assert SendingQueue.pop(test) == :error
  end

  test "Alert can be added to the queue", %{test: test, notification: notification} do
    SendingQueue.start_link([name: test])
    :ok = SendingQueue.enqueue(test, notification)
    assert SendingQueue.pop(test) == {:ok, notification}
  end

  test "Alert can be removed from the queue", %{test: test, notification: notification} do
    SendingQueue.start_link([name: test])
    :ok = SendingQueue.enqueue(test, notification)

    assert SendingQueue.pop(test) == {:ok, notification}
    assert SendingQueue.pop(test) == :error
  end

  test "Duplicate notifications are not enqueued", %{test: test} do
    notification1 = %Notification{alert_id: "1", user_id: "1"}
    notification2 = %Notification{alert_id: "1", user_id: "1"}
    SendingQueue.start_link([name: test])
    SendingQueue.enqueue(test, notification1)
    SendingQueue.enqueue(test, notification2)

    {:ok, notification} = SendingQueue.pop(test)
    assert notification == notification1
    assert notification == notification2
    assert :error = SendingQueue.pop(test)
  end
end
