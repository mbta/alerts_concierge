defmodule MbtaServer.AlertProcessor.SendingQueueTest do
  use MbtaServer.Web.ConnCase
  alias MbtaServer.AlertProcessor.{SendingQueue, Model.Notification}

  setup do
    {:ok, notification: %Notification{send_after: NaiveDateTime.utc_now()}}
  end

  test "Instantiates empty queue by default" do
    assert SendingQueue.pop == :error
  end

  test "Alert can be added to the queue", %{notification: notification} do
    :ok = SendingQueue.enqueue(notification)
    assert SendingQueue.pop == {:ok, notification}
  end

  test "Alert can be removed from the queue", %{notification: notification} do
    :ok = SendingQueue.enqueue(notification)

    assert SendingQueue.pop == {:ok, notification}
    assert SendingQueue.pop == :error
  end
end
