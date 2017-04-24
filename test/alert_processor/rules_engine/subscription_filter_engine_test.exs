defmodule MbtaServer.AlertProcessor.SubscriptionFilterEngineTest do
  use MbtaServer.DataCase
  import MbtaServer.Factory
  alias MbtaServer.AlertProcessor.{Model.Alert, Model.InformedEntity, SubscriptionFilterEngine}

  test "process_alert/1 when message provided" do
    user = insert(:user)
    insert(:subscription, user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1}])
    alert = %Alert{header: "This is a test message", id: "1", effect_name: "Delay", severity: :minor, informed_entities: [%{route_type: 1}]}
    assert [{:ok, _} | _t] = SubscriptionFilterEngine.process_alert(alert)
  end

  test "process_alert/1 when message not provided" do
    user = insert(:user)
    insert(:subscription, user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1}])
    alert = %Alert{header: nil, id: "1", effect_name: "Delay", severity: :minor, informed_entities: [%{route_type: 1}]}
    assert [{:error, _} | _t] = SubscriptionFilterEngine.process_alert(alert)
  end
end
