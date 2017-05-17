defmodule AlertProcessor.HoldingQueueTest do
  use ExUnit.Case

  alias AlertProcessor.{HoldingQueue, SendingQueue, Model.Notification}

  defp generate_date(x) do
    DateTime.from_unix!(System.system_time(:millisecond) + x, :millisecond)
  end

  setup do
    date_in_future = DateTime.from_unix!(4_078_579_247)
    future_notification = %Notification{send_after: date_in_future}

    {:ok, fn: future_notification}
  end

  setup do
    Application.stop(:alert_processor)
    on_exit(self(), fn() -> Application.start(:alert_processor) end)
  end

  test "Instantiates empty queue by default" do
    HoldingQueue.start_link()
    assert HoldingQueue.pop == :error
  end

  test "Instantiates queue with future notifications when provided", %{fn: future_notification} do
    notifications = [future_notification]
    HoldingQueue.start_link(notifications)

    assert HoldingQueue.pop() == {:ok, future_notification}
  end

  test "Alert can be added to the queue", %{fn: future_notification} do
    HoldingQueue.start_link()
    HoldingQueue.enqueue(future_notification)

    assert HoldingQueue.pop == {:ok, future_notification}
  end

  test "messages_to_send/1 retains all notifications for the future" do
    SendingQueue.start_link()
    notification_to_not_filter = %Notification{send_after: generate_date(50)}
    notification_to_filter = %Notification{send_after: generate_date(-50)}
    notifications = [notification_to_not_filter, notification_to_filter]
    HoldingQueue.start_link(notifications)

    assert HoldingQueue.notifications_to_send(generate_date(0)) == {:ok, [notification_to_filter]}
    assert HoldingQueue.pop == {:ok, notification_to_not_filter}
  end

  test "remove_notifications/1 filters out notifications matching list of alert ids" do
    notification = %Notification{alert_id: "1"}
    HoldingQueue.start_link([notification])

    :ok = HoldingQueue.remove_notifications(["1"])

    assert HoldingQueue.pop == :error
  end

  test "remove_notifications/1 does not filter anything if passed empty list" do
    notification = %Notification{alert_id: "1"}
    HoldingQueue.start_link([notification])

    :ok = HoldingQueue.remove_notifications([])

    assert HoldingQueue.pop == {:ok, notification}
  end

  test "remove_user_notifications/1 filters out notifications for specific user_id" do
    notification1 = %Notification{alert_id: "1", user_id: "1"}
    notification2 = %Notification{alert_id: "2", user_id: "1"}
    notification3 = %Notification{alert_id: "3", user_id: "2"}
    HoldingQueue.start_link([notification1, notification2, notification3])

    :ok = HoldingQueue.remove_user_notifications("1")
    assert HoldingQueue.pop == {:ok, notification3}
    assert HoldingQueue.pop == :error
  end

  test "remove_user_notifications/1 does not affect state if user_id has no notifications pending" do
    notification = %Notification{alert_id: "1", user_id: "1"}
    HoldingQueue.start_link([notification])

    :ok = HoldingQueue.remove_user_notifications("2")
    assert HoldingQueue.pop == {:ok, notification}
    assert HoldingQueue.pop == :error
  end

  test "Duplicate notifications are not enqueued" do
    notification1 = %Notification{alert_id: "1", user_id: "1"}
    notification2 = %Notification{alert_id: "1", user_id: "1"}
    HoldingQueue.start_link()
    HoldingQueue.enqueue(notification1)
    HoldingQueue.enqueue(notification2)

    {:ok, notification} = HoldingQueue.pop()
    assert notification == notification1
    assert notification == notification2
    assert :error = HoldingQueue.pop()
  end
end
