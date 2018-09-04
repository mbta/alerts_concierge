defmodule AlertProcessor.AlertWorkerTest do
  use ExUnit.Case, async: true
  alias AlertProcessor.AlertWorker

  test "worker calls alert parser" do
    {:noreply, _} = AlertWorker.handle_info({:work, 0, DateTime.utc_now()}, nil)
    assert_received :processed_alerts
  end
end
