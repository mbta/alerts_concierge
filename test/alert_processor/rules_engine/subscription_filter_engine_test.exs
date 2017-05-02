defmodule MbtaServer.AlertProcessor.SubscriptionFilterEngineTest do
  use MbtaServer.DataCase
  import MbtaServer.Factory
  alias MbtaServer.AlertProcessor.{Model.Alert, Model.InformedEntity, SubscriptionFilterEngine}

  setup do
    alert = %Alert{
      active_period: [%{start: ~N[2017-04-26 09:00:00], end: ~N[2017-04-26 19:00:00]}],
      effect_name: "Delay",
      header: "This is a test message",
      id: "1",
      informed_entities: [%{route_type: 1}],
      severity: :minor
    }
    {:ok, alert: alert}
  end

  test "process_alert/1 when message provided", %{alert: alert} do
    user = insert(:user, phone_number: nil)
    build(:subscription, user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1}])
    |> weekday_subscription
    |> insert
    assert [{:ok, _} | _t] = SubscriptionFilterEngine.process_alert(alert)
  end

  test "process_alert/1 when message not provided", %{alert: alert} do
    user = insert(:user, phone_number: nil)
    build(:subscription, user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1}])
    |> weekday_subscription
    |> insert
    assert [{:error, _} | _t] = SubscriptionFilterEngine.process_alert(Map.put(alert, :header, nil))
  end
end
