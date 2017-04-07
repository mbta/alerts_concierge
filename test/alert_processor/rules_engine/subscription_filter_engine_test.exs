defmodule MbtaServer.AlertProcessor.SubscriptionFilterEngineTest do
  use MbtaServer.DataCase
  import MbtaServer.Factory
  alias MbtaServer.AlertProcessor.{SubscriptionFilterEngine}

  test "process_alert/1 when message provided" do
    user = insert(:user)
    alert = %{header: "This is a test message", alert_id: "1"}
    {:ok, _} = SubscriptionFilterEngine.process_alert(alert, user)
  end

  test "process_alert/1 when message not provided" do
    user = insert(:user)
    alert = %{header: nil, alert_id: "1"}
    {:error, _} = SubscriptionFilterEngine.process_alert(alert, user)
  end
end
