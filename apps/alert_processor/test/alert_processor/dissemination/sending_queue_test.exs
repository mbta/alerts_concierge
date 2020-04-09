defmodule AlertProcessor.SendingQueueTest do
  @moduledoc false
  use ExUnit.Case
  alias AlertProcessor.{SendingQueue, Model.Notification}

  setup_all do
    {:ok, notification: %Notification{send_after: DateTime.utc_now()}}
  end

  test "Instantiates empty queue by default", %{test: test} do
    SendingQueue.start_link(name: test)
    assert SendingQueue.pop(test) == :error
  end

  test "Alert can be added to the queue", %{test: test, notification: notification} do
    SendingQueue.start_link(name: test)
    :ok = SendingQueue.enqueue(test, notification)
    assert SendingQueue.pop(test) == {:ok, notification}
  end

  test "Alert can be removed from the queue", %{test: test, notification: notification} do
    SendingQueue.start_link(name: test)
    :ok = SendingQueue.enqueue(test, notification)

    assert SendingQueue.pop(test) == {:ok, notification}
    assert SendingQueue.pop(test) == :error
  end

  test "Multiple alerts can be added to the queue", %{test: test} do
    notification1 = %Notification{alert_id: "1"}
    notification2 = %Notification{alert_id: "2"}
    notification3 = %Notification{alert_id: "3"}
    SendingQueue.start_link(name: test)
    SendingQueue.list_enqueue(test, [notification1])
    SendingQueue.list_enqueue(test, [notification2, notification3])

    assert SendingQueue.pop(test) == {:ok, notification2}
    assert SendingQueue.pop(test) == {:ok, notification3}
    assert SendingQueue.pop(test) == {:ok, notification1}
  end

  test "We can get the number of items in the queue", %{test: test} do
    notification1 = %Notification{alert_id: "1"}
    notification2 = %Notification{alert_id: "2"}
    SendingQueue.start_link(name: test)
    SendingQueue.enqueue(test, notification1)
    SendingQueue.enqueue(test, notification2)

    assert {:ok, 2} = SendingQueue.queue_length(test)
    SendingQueue.pop(test)
    SendingQueue.pop(test)
    assert {:ok, 0} = SendingQueue.queue_length(test)
  end
end
