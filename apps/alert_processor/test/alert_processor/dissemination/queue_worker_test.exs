defmodule AlertProcessor.QueueWorkerTest do
  use ExUnit.Case
  alias AlertProcessor.{HoldingQueue, SendingQueue, QueueWorker, Model.Notification}

  defp generate_date(x) do
    DateTime.from_unix!(System.system_time(:millisecond) + x, :millisecond)
  end

  setup_all do
    notification = %Notification{send_after: DateTime.utc_now()}
    later_notification = %Notification{send_after: generate_date(50)}

    {:ok, notification: notification, later_notification: later_notification}
  end

  test "Worker passes notifications from holding queue to sending queue", %{notification: notification} do
    {:ok, hq_pid} = HoldingQueue.start_link([], [name: :qwt_holding_queue_1])
    {:ok, sq_pid} = SendingQueue.start_link([name: :qwt_sending_queue_1])
    {:ok, _qw_pid} = QueueWorker.start_link({:qwt_holding_queue_1, :qwt_sending_queue_1}, [name: :qwt_queue_worker_1])

    assert HoldingQueue.pop(hq_pid) == :error
    assert SendingQueue.pop(sq_pid) == :error
    HoldingQueue.enqueue(hq_pid, notification)

    :timer.sleep(100)

    assert HoldingQueue.pop(hq_pid) == :error
    assert SendingQueue.pop(sq_pid) == {:ok, notification}
  end

  test "Worker is recurring", %{notification: notification, later_notification: later_notification} do
    {:ok, hq_pid} = HoldingQueue.start_link([], [name: :qwt_holding_queue_2])
    {:ok, sq_pid} = SendingQueue.start_link([name: :qwt_sending_queue_2])
    {:ok, _qw_pid} = QueueWorker.start_link({:qwt_holding_queue_2, :qwt_sending_queue_2}, [name: :qwt_queue_worker_2])

    assert HoldingQueue.pop(hq_pid) == :error
    assert SendingQueue.pop(sq_pid) == :error

    HoldingQueue.enqueue(hq_pid, notification)
    :timer.sleep(50)

    assert SendingQueue.pop(sq_pid) == {:ok, notification}
    assert HoldingQueue.pop(hq_pid) == :error

    HoldingQueue.enqueue(hq_pid, later_notification)
    :timer.sleep(50)

    assert SendingQueue.pop(sq_pid) == {:ok, later_notification}
    assert SendingQueue.pop(sq_pid) == :error
  end
end
