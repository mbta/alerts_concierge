defmodule MbtaServer.AlertProcessor.SendingQueueTest do
  use MbtaServer.Web.ConnCase
  alias MbtaServer.AlertProcessor.{SendingQueue, Model.AlertMessage}

  setup do
    {:ok, message: %AlertMessage{send_after: DateTime.utc_now()}}
  end

  test "Instantiates empty queue by default" do
    assert SendingQueue.pop == :error
  end

  test "Alert can be added to the queue", %{message: message} do
    SendingQueue.enqueue(message)
    assert SendingQueue.pop == {:ok, message}
  end

  test "Alert can be removed from the queue", %{message: message} do
    SendingQueue.enqueue(message)

    assert SendingQueue.pop == {:ok, message}
    assert SendingQueue.pop == :error
  end
end
