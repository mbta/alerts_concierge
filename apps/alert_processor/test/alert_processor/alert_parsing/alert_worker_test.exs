defmodule AlertProcessor.AlertWorkerTest do
  use ExUnit.Case
  alias AlertProcessor.AlertWorker

  test "worker calls alert parser" do
    {:noreply, _} = AlertWorker.handle_info(:work, nil)
    assert_received :processed_alerts
  end
end
