defmodule AlertProcessor.SendingQueueTest do
  @moduledoc false
  use ExUnit.Case
  alias AlertProcessor.{SendingQueue, Model.Notification}

  setup %{test: test} do
    {:ok, _} = SendingQueue.start_link(name: test)
    :ok
  end

  test "starts empty", %{test: test} do
    assert SendingQueue.length(test) == 0
    assert SendingQueue.pop(test) == :error
  end

  test "pushes and pops notifications in queue order", %{test: test} do
    notification1 = %Notification{alert_id: "1"}
    notification2 = %Notification{alert_id: "2"}
    notification3 = %Notification{alert_id: "3"}

    SendingQueue.push(test, notification1)
    SendingQueue.push(test, notification2)
    SendingQueue.push(test, notification3)

    assert SendingQueue.pop(test) == {:ok, notification1}
    assert SendingQueue.pop(test) == {:ok, notification2}
    assert SendingQueue.pop(test) == {:ok, notification3}
    assert SendingQueue.pop(test) == :error
  end

  test "pushes a list of notifications in list order", %{test: test} do
    notification1 = %Notification{alert_id: "7"}
    notification2 = %Notification{alert_id: "8"}
    notification3 = %Notification{alert_id: "9"}

    SendingQueue.push_list(test, [notification1, notification2, notification3])

    assert SendingQueue.pop(test) == {:ok, notification1}
    assert SendingQueue.pop(test) == {:ok, notification2}
    assert SendingQueue.pop(test) == {:ok, notification3}
  end

  test "gets the number of notifications in the queue", %{test: test} do
    SendingQueue.push(test, %Notification{alert_id: "a"})
    SendingQueue.push(test, %Notification{alert_id: "b"})
    SendingQueue.push(test, %Notification{alert_id: "c"})
    SendingQueue.pop(test)

    assert SendingQueue.length(test) == 2
  end

  test "resets the queue to empty", %{test: test} do
    SendingQueue.push(test, %Notification{alert_id: "z"})

    SendingQueue.reset()

    assert SendingQueue.pop() == :error
  end
end
