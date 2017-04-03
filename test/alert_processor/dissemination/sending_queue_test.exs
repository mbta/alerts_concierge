defmodule MbtaServer.AlertProcessor.SendingQueueTest do
  use MbtaServer.Web.ConnCase

  alias MbtaServer.AlertProcessor.{SendingQueue, Model.AlertMessage}

  setup do
    {:ok, message: %AlertMessage{send_after: DateTime.utc_now()}}
  end

  test "Instantiates empty queue by default" do
    {:ok, queue} = SendingQueue.start_link()
    assert :sys.get_state(queue) == {[], []}
  end

  test "Alert can be added to the queue", %{message: message} do
    {:ok, queue} = SendingQueue.start_link()
    SendingQueue.enqueue(message)
    assert :sys.get_state(queue) == {[message], []}
  end

  test "Alert can be removed from the queue", %{message: message} do
    {:ok, queue} = SendingQueue.start_link()
    SendingQueue.enqueue(message)
    assert :sys.get_state(queue) == {[message], []}

    assert message == SendingQueue.pop
    assert :sys.get_state(queue) == {[], []}
  end
end
