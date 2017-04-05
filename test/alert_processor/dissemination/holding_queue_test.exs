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
    {:ok, queue} = HoldingQueue.start_link()
    assert :sys.get_state(queue) ==  []
  end

  test "Instantiates queue with future alerts when provided", %{fm: fm} do
    alerts = [fm]
    {:ok, loaded_queue} = HoldingQueue.start_link(alerts)

    assert :sys.get_state(loaded_queue) == [fm]
  end

  test "Filters queue immediately when instantiated", %{fm: fm, pm: pm} do
    {:ok, _sq} = SendingQueue.start_link()
    alerts = [fm, pm]
    {:ok, loaded_queue} = HoldingQueue.start_link(alerts)

    assert :sys.get_state(loaded_queue) == [fm]
  end

  test "Alert can be added to the queue", %{fm: fm} do
    {:ok, queue} = HoldingQueue.start_link()
    HoldingQueue.enqueue(fm)
    assert :sys.get_state(queue) == [fm]
  end

  test "Filtering the queue retains all alerts for the future" do
    {:ok, _sq} = SendingQueue.start_link()
    alert_to_not_filter = %AlertMessage{send_after: generate_date(250)}
    alert_to_filter = %AlertMessage{send_after: generate_date(50)}
    alerts = [alert_to_not_filter, alert_to_filter]
    {:ok, loaded_queue} = HoldingQueue.start_link(alerts)

    :timer.sleep(100)
    assert :sys.get_state(loaded_queue) == [alert_to_not_filter]
  end

  test "Filtering the queue pushes sendable alerts to SendingQueue" do
    alert = %AlertMessage{send_after: generate_date(50)}
    alerts = [alert]

    {:ok, sending_queue} = SendingQueue.start_link()
    {:ok, loaded_queue} = HoldingQueue.start_link(alerts)

    :timer.sleep(100)
    assert :sys.get_state(loaded_queue) == []
    assert :sys.get_state(sending_queue) == [alert]
  end
end
