defmodule AlertProcessor.QueueWorkerTest do
  use ExUnit.Case
  alias AlertProcessor.{HoldingQueue, SendingQueue, QueueWorker, Model.Notification}

  defp generate_date(x) do
    DateTime.from_unix!(System.system_time(:millisecond) + x, :millisecond)
  end

  setup do
    Application.stop(:alert_processor)
    on_exit(self(), fn() -> Application.start(:alert_processor) end)
    notification = %Notification{send_after: DateTime.utc_now()}
    later_notification = %Notification{send_after: generate_date(50)}

    {:ok, notification: notification, later_notification: later_notification}
  end

  test "Worker passes notifications from holding queue to sending queue", %{notification: notification} do
    HoldingQueue.start_link
    SendingQueue.start_link
    QueueWorker.start_link

    assert HoldingQueue.pop == :error
    assert SendingQueue.pop == :error
    HoldingQueue.enqueue(notification)

    :timer.sleep(100)

    assert HoldingQueue.pop == :error
    assert SendingQueue.pop == {:ok, notification}
  end

  test "Worker is recurring", %{notification: notification, later_notification: later_notification} do
    HoldingQueue.start_link
    SendingQueue.start_link
    QueueWorker.start_link

    assert HoldingQueue.pop == :error
    assert SendingQueue.pop == :error

    HoldingQueue.enqueue(notification)
    :timer.sleep(50)

    assert SendingQueue.pop == {:ok, notification}
    assert HoldingQueue.pop == :error

    HoldingQueue.enqueue(later_notification)
    :timer.sleep(50)

    assert SendingQueue.pop == {:ok, later_notification}
    assert SendingQueue.pop == :error
  end
end
