defmodule MbtaServer.AlertProcessor.HoldingQueueTest do
  use MbtaServer.Web.ConnCase

  alias MbtaServer.AlertProcessor.{HoldingQueue, SendingQueue, Model.AlertMessage}

  defp generate_date(x) do
    DateTime.from_unix!(System.system_time(:millisecond) + x, :millisecond)
  end

  setup do
    date_in_future = DateTime.from_unix!(4078579247)
    date_in_past = DateTime.from_unix!(1)
    future_message = %AlertMessage{send_after: date_in_future}
    past_message = %AlertMessage{send_after: date_in_past}

    {:ok, fm: future_message, pm: past_message}
  end

  setup do
    Application.stop(:mbta_server)
    on_exit(self(), fn() -> Application.start(:mbta_server) end)
  end

  test "Instantiates empty queue by default" do
    HoldingQueue.start_link()
    assert HoldingQueue.pop == :error
  end

  test "Instantiates queue with future alerts when provided", %{fm: fm} do
    alerts = [fm]
    HoldingQueue.start_link(alerts)

    assert HoldingQueue.pop() == {:ok, fm}
  end

  test "Alert can be added to the queue", %{fm: fm} do
    HoldingQueue.start_link()
    HoldingQueue.enqueue(fm)

    assert HoldingQueue.pop == {:ok, fm}
  end

  test "messages_to_send/1 retains all alerts for the future" do
    SendingQueue.start_link()
    alert_to_not_filter = %AlertMessage{send_after: generate_date(50)}
    alert_to_filter = %AlertMessage{send_after: generate_date(-50)}
    alerts = [alert_to_not_filter, alert_to_filter]
    HoldingQueue.start_link(alerts)

    assert HoldingQueue.messages_to_send(generate_date(0)) == {:ok, [alert_to_filter]}
    assert HoldingQueue.pop == {:ok, alert_to_not_filter}
  end
end
