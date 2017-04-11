defmodule MbtaServer.AlertProcessor.HoldingQueueTest do
  use MbtaServer.Web.ConnCase

  alias MbtaServer.AlertProcessor.{HoldingQueue, SendingQueue, Model.Notification}

  defp generate_date(x) do
    DateTime.from_unix!(System.system_time(:millisecond) + x, :millisecond)
  end

  setup do
    date_in_future = DateTime.from_unix!(4078579247)
    future_notification = %Notification{send_after: date_in_future}

    {:ok, fn: future_notification}
  end

  setup do
    Application.stop(:mbta_server)
    on_exit(self(), fn() -> Application.start(:mbta_server) end)
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
end
