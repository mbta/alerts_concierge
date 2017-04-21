defmodule MbtaServer.AlertProcessor.SeverityFilterTest do
  use MbtaServer.DataCase
  alias MbtaServer.AlertProcessor
  alias AlertProcessor.{SeverityFilter, Model.Alert, Model.InformedEntity}
  import MbtaServer.Factory

  test "subscription with medium alert priority type will not send alert for minor severity alert" do
    alert = %Alert{informed_entities: [%{route: "Red", route_type: 1}], severity: :minor, effect_name: "Delay"}
    sub1 = insert(:subscription, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub2 = insert(:subscription, alert_priority_type: :medium, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])

    assert {:ok, [sub1.id], alert} == SeverityFilter.filter({:ok, [sub1.id, sub2.id], alert})
  end

  test "subscription with any alert priority type will send alert for minor severity alert" do
    alert = %Alert{informed_entities: [%{route_type: 1, route: "Red"}], severity: :minor, effect_name: "Schedule Change"}
    sub1 = insert(:subscription, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub2 = insert(:subscription, alert_priority_type: :medium, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub3 = insert(:subscription, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])

    assert {:ok, [sub1.id, sub2.id, sub3.id], alert} == SeverityFilter.filter({:ok, [sub1.id, sub2.id, sub3.id], alert})
  end

  test "will not send alert if should not receive based on severity setting regardless of alert_priority_type" do
    alert = %Alert{informed_entities: [%{route_type: 1, route: "Red"}], severity: :minor, effect_name: "Extra Service"}
    sub1 = insert(:subscription, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub2 = insert(:subscription, alert_priority_type: :medium, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub3 = insert(:subscription, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])

    assert {:ok, [], alert} == SeverityFilter.filter({:ok, [sub1.id, sub2.id, sub3.id], alert})
  end

  test "will send systemwide alerts" do
    alert = %Alert{informed_entities: [%{route_type: 1}], severity: :minor, effect_name: "Policy Change"}
    sub = insert(:subscription, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])

    assert {:ok, [sub.id], alert} == SeverityFilter.filter({:ok, [sub.id], alert})
  end

  test "will not send systemwide alert if should not receive based on alert severity regardless of alert_priority_type" do
    alert = %Alert{informed_entities: [%{route_type: 1}], severity: :minor, effect_name: "Extra Service"}
    sub1 = insert(:subscription, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub2 = insert(:subscription, alert_priority_type: :medium, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub3 = insert(:subscription, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])

    assert {:ok, [], alert} == SeverityFilter.filter({:ok, [sub1.id, sub2.id, sub3.id], alert})
  end
end
