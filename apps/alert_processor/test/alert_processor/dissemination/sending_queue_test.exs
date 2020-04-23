defmodule AlertProcessor.SendingQueueTest do
  @moduledoc false
  use ExUnit.Case
  alias AlertProcessor.{SendingQueue, Model.Notification}

  setup %{test: test} do
    {:ok, _} = SendingQueue.start_link(name: test)
    {:ok, notification: %Notification{send_after: DateTime.utc_now()}}
  end

  test "starts empty", %{test: test} do
    assert SendingQueue.length(test) == 0
    assert SendingQueue.pop(test) == :error
  end

  test "can push and pop notifications", %{test: test, notification: notification} do
    :ok = SendingQueue.push(test, notification)

    assert SendingQueue.pop(test) == {:ok, notification}
    assert SendingQueue.pop(test) == :error
  end

  test "pops notifications in the order they were pushed", %{test: test} do
    notification1 = %Notification{alert_id: "1"}
    notification2 = %Notification{alert_id: "2"}
    notification3 = %Notification{alert_id: "3"}

    SendingQueue.push(test, notification1)
    SendingQueue.push(test, notification2)
    SendingQueue.push(test, notification3)

    assert SendingQueue.pop(test) == {:ok, notification1}
    assert SendingQueue.pop(test) == {:ok, notification2}
    assert SendingQueue.pop(test) == {:ok, notification3}
  end

  test "can get the number of notifications in the queue", %{test: test} do
    SendingQueue.push(test, %Notification{alert_id: "a"})
    SendingQueue.push(test, %Notification{alert_id: "b"})
    SendingQueue.push(test, %Notification{alert_id: "c"})
    SendingQueue.pop(test)

    assert SendingQueue.length(test) == 2
  end

  test "can reset the queue to empty", %{test: test, notification: notification} do
    SendingQueue.push(test, notification)

    SendingQueue.reset()

    assert SendingQueue.pop() == :error
  end
end
