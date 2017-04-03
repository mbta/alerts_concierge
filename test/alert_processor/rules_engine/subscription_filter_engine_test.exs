defmodule MbtaServer.AlertProcessor.SubscriptionFilterEngineTest do
  use MbtaServer.DataCase
  import MbtaServer.Factory
  alias MbtaServer.AlertProcessor.{SubscriptionFilterEngine}

  test "process_alert/1 when message provided" do
    insert(:user)
    alert = %{header: "This is a test message"}
    {:ok, _} = SubscriptionFilterEngine.process_alert(alert)
  end

  test "process_alert/1 when message not provided" do
    insert(:user)
    alert = %{header: nil}
    {:error, _} = SubscriptionFilterEngine.process_alert(alert)
  end
end
