defmodule MbtaServer.AlertProcessor.AlertWorkerTest do
  use MbtaServer.Web.ConnCase
  alias MbtaServer.AlertProcessor.AlertWorker

  test "worker calls alert parser" do
    {:noreply, _} = AlertWorker.handle_info(:work, nil)
    assert_received :processed_alerts
  end
end
