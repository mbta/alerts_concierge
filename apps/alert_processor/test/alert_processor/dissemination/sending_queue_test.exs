defmodule AlertProcessor.SendingQueueTest do
  use ExUnit.Case
  alias AlertProcessor.{SendingQueue, Model.Notification}

  setup do
    Application.stop(:alert_processor)
    on_exit(self(), fn() -> Application.start(:alert_processor) end)

    {:ok, notification: %Notification{send_after: DateTime.utc_now()}}
  end

  test "Instantiates empty queue by default" do
    SendingQueue.start_link()
    assert SendingQueue.pop == :error
  end

  test "Alert can be added to the queue", %{notification: notification} do
    SendingQueue.start_link()
    :ok = SendingQueue.enqueue(notification)
    assert SendingQueue.pop == {:ok, notification}
  end

  test "Alert can be removed from the queue", %{notification: notification} do
    SendingQueue.start_link()
    :ok = SendingQueue.enqueue(notification)

    assert SendingQueue.pop == {:ok, notification}
    assert SendingQueue.pop == :error
  end

  test "Duplicate notifications are not enqueued" do
    notification1 = %Notification{alert_id: "1", user_id: "1"}
    notification2 = %Notification{alert_id: "1", user_id: "1"}
    SendingQueue.start_link()
    SendingQueue.enqueue(notification1)
    SendingQueue.enqueue(notification2)

    {:ok, notification} = SendingQueue.pop()
    assert notification == notification1
    assert notification == notification2
    assert :error = SendingQueue.pop()
  end
end
