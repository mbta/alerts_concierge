defmodule AlertProcessor.HoldingQueueTest do
  use AlertProcessor.DataCase

  import AlertProcessor.Factory
  alias AlertProcessor.{HoldingQueue, Model.Alert, Model.Notification}

  defp generate_date(x) do
    DateTime.from_unix!(System.system_time(:millisecond) + x, :millisecond)
  end

  setup_all do
    date_in_future = DateTime.from_unix!(4_078_579_247)
    future_notification = %Notification{send_after: date_in_future}

    {:ok, fn: future_notification}
  end

  test "Instantiates empty queue by default", %{test: test} do
    HoldingQueue.start_link([], [name: test])
    assert HoldingQueue.pop(test) == :error
  end

  test "Instantiates queue with future notifications when provided", %{test: test, fn: future_notification} do
    notifications = [future_notification]
    HoldingQueue.start_link(notifications, [name: test])

    assert HoldingQueue.pop(test) == {:ok, future_notification}
  end

  test "Alert can be added to the queue", %{test: test, fn: future_notification} do
    HoldingQueue.start_link([], [name: test])
    HoldingQueue.enqueue(test, future_notification)

    assert HoldingQueue.pop(test) == {:ok, future_notification}
  end

  test "messages_to_send/1 retains all notifications for the future", %{test: test} do
    notification_to_not_filter = %Notification{send_after: generate_date(50)}
    notification_to_filter = %Notification{send_after: generate_date(-50)}
    notifications = [notification_to_not_filter, notification_to_filter]
    HoldingQueue.start_link(notifications, [name: test])

    assert HoldingQueue.notifications_to_send(test, generate_date(0)) == {:ok, [notification_to_filter]}
    assert HoldingQueue.pop(test) == {:ok, notification_to_not_filter}
  end

  test "remove_notifications/1 filters out notifications matching list of alert ids", %{test: test} do
    notification = %Notification{alert_id: "1"}
    HoldingQueue.start_link([notification], [name: test])

    :ok = HoldingQueue.remove_notifications(test, ["1"])

    assert HoldingQueue.pop(test) == :error
  end

  test "remove_notifications/1 does not filter anything if passed empty list", %{test: test} do
    notification = %Notification{alert_id: "1"}
    HoldingQueue.start_link([notification], [name: test])

    :ok = HoldingQueue.remove_notifications(test, [])

    assert HoldingQueue.pop(test) == {:ok, notification}
  end

  test "remove_user_notifications/1 filters out notifications for specific user_id", %{test: test} do
    notification1 = %Notification{alert_id: "1", user_id: "1"}
    notification2 = %Notification{alert_id: "2", user_id: "1"}
    notification3 = %Notification{alert_id: "3", user_id: "2"}
    HoldingQueue.start_link([notification1, notification2, notification3], [name: test])

    :ok = HoldingQueue.remove_user_notifications(test, "1")
    assert HoldingQueue.pop(test) == {:ok, notification3}
    assert HoldingQueue.pop(test) == :error
  end

  test "remove_user_notifications/1 does not affect state if user_id has no notifications pending", %{test: test} do
    notification = %Notification{alert_id: "1", user_id: "1"}
    HoldingQueue.start_link([notification], [name: test])

    :ok = HoldingQueue.remove_user_notifications("2")
    assert HoldingQueue.pop(test) == {:ok, notification}
    assert HoldingQueue.pop(test) == :error
  end

  test "Duplicate notifications based on user_id + alert_id are not enqueued", %{test: test} do
    user = insert(:user)
    alert1 = %Alert{id: "1", active_period: [%{start: DateTime.from_naive!(~N[2017-12-25 12:00:00], "Etc/UTC"), end: DateTime.from_naive!(~N[2017-12-25 15:00:00], "Etc/UTC")}]}
    alert2 = %Alert{id: "1", active_period: [%{start: DateTime.from_naive!(~N[2017-12-25 12:00:00], "Etc/UTC"), end: DateTime.from_naive!(~N[2017-12-25 16:00:00], "Etc/UTC")}]}
    send_after = DateTime.from_naive!(~N[2017-12-25 12:00:00], "Etc/UTC")

    notification1 = %Notification{alert_id: "1", user_id: user.id, user: user, alert: alert1, send_after: send_after}
    notification2 = %Notification{alert_id: "1", user_id: user.id, user: user, alert: alert2, send_after: send_after}
    HoldingQueue.start_link([], [name: test])
    HoldingQueue.enqueue(test, notification1)
    HoldingQueue.enqueue(test, notification2)

    {:ok, notification} = HoldingQueue.pop(test)
    assert notification == notification2
    assert :error = HoldingQueue.pop(test)
  end
end
