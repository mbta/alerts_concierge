defmodule MbtaServer.AlertProcessor.SendingQueueTest do
  use MbtaServer.Web.ConnCase

  alias MbtaServer.AlertProcessor.{SendingQueue, Model.AlertMessage}

  setup do
    {:ok, message: %AlertMessage{send_after: DateTime.utc_now()}}
  end

  test "Instantiates empty queue by default" do
    {:ok, _queue} = SendingQueue.start_link()
    assert SendingQueue.pop == nil
  end

  test "Alert can be added to the queue", %{message: message} do
    {:ok, _queue} = SendingQueue.start_link()
    assert SendingQueue.pop == nil
    SendingQueue.enqueue(message)
    assert SendingQueue.pop == message
  end

  test "Alert can be removed from the queue", %{message: message} do
    {:ok, _queue} = SendingQueue.start_link()
    SendingQueue.enqueue(message)

    assert SendingQueue.pop == message
    assert SendingQueue.pop == nil
  end
end
