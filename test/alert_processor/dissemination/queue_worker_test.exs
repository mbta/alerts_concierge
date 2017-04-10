defmodule MbtaServer.AlertProcessor.QueueWorkerTest do
  use MbtaServer.Web.ConnCase, async: false
  alias MbtaServer.AlertProcessor.{HoldingQueue, SendingQueue, QueueWorker, Model.AlertMessage}

  defp generate_date(x) do
    DateTime.from_unix!(System.system_time(:millisecond) + x, :millisecond)
  end

  setup do
    message = %AlertMessage{send_after: DateTime.utc_now()}
    later_message = %AlertMessage{send_after: generate_date(50)}

    {:ok, message: message, later_message: later_message}
  end

  setup do
    Application.stop(:mbta_server)
    on_exit(self(), fn() -> Application.start(:mbta_server) end)
  end

  test "Worker passes messages from holding queue to sending queue", %{message: message} do
    MbtaServer.AlertProcessor.start_link

    assert HoldingQueue.pop == {:error, :empty}
    assert SendingQueue.pop == {:error, :empty}
    HoldingQueue.enqueue(message)

    :timer.sleep(100)

    assert HoldingQueue.pop == {:error, :empty}
    assert SendingQueue.pop == message
  end

  test "Worker is recurring", %{message: message, later_message: later_message} do
    HoldingQueue.start_link
    SendingQueue.start_link
    QueueWorker.start_link

    assert HoldingQueue.pop == {:error, :empty}
    assert SendingQueue.pop == {:error, :empty}

    HoldingQueue.enqueue(message)
    :timer.sleep(50)

    assert SendingQueue.pop == message
    assert HoldingQueue.pop == {:error, :empty}

    HoldingQueue.enqueue(later_message)
    :timer.sleep(50)

    assert SendingQueue.pop == later_message
    assert SendingQueue.pop == {:error, :empty}
  end
end
