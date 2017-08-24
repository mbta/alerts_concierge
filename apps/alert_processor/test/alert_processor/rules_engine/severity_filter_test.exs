defmodule AlertProcessor.SeverityFilterTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.{SeverityFilter, Model.Alert, Model.InformedEntity}
  import AlertProcessor.Factory

  test "subscription with medium alert priority type will not send alert for minor severity alert" do
    alert = %Alert{informed_entities: [%InformedEntity{route: "Red", route_type: 1}], severity: :minor, effect_name: "Delay"}
    sub1 = insert(:subscription, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub2 = insert(:subscription, alert_priority_type: :medium, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])

    assert {:ok, [sub1], alert} == SeverityFilter.filter({:ok, [sub1, sub2], alert})
  end

  test "subscription with any alert priority type will send alert for minor severity alert" do
    alert = %Alert{informed_entities: [%InformedEntity{route_type: 1, route: "Red"}], severity: :minor, effect_name: "Schedule Change"}
    sub1 = insert(:subscription, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub2 = insert(:subscription, alert_priority_type: :medium, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub3 = insert(:subscription, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])

    assert {:ok, [sub1, sub2, sub3], alert} == SeverityFilter.filter({:ok, [sub1, sub2, sub3], alert})
  end

  test "will not send alert if should not receive based on severity setting regardless of alert_priority_type" do
    alert = %Alert{informed_entities: [%InformedEntity{route_type: 1, route: "Red"}], severity: :minor, effect_name: "Extra Service"}
    sub1 = insert(:subscription, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub2 = insert(:subscription, alert_priority_type: :medium, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub3 = insert(:subscription, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])

    assert {:ok, [], alert} == SeverityFilter.filter({:ok, [sub1, sub2, sub3], alert})
  end

  test "will send systemwide alerts" do
    alert = %Alert{informed_entities: [%InformedEntity{route_type: 1}], severity: :minor, effect_name: "Policy Change"}
    sub = insert(:subscription, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])

    assert {:ok, [sub], alert} == SeverityFilter.filter({:ok, [sub], alert})
  end

  test "will not send systemwide alert if should not receive based on alert severity regardless of alert_priority_type" do
    alert = %Alert{informed_entities: [%InformedEntity{route_type: 1}], severity: :minor, effect_name: "Extra Service"}
    sub1 = insert(:subscription, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub2 = insert(:subscription, alert_priority_type: :medium, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])
    sub3 = insert(:subscription, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])

    assert {:ok, [], alert} == SeverityFilter.filter({:ok, [sub1, sub2, sub3], alert})
  end

  test "will send facility alerts regardless of severity" do
    alert = %Alert{informed_entities: [%InformedEntity{facility_type: :elevator, stop: "70026"}], severity: :minor, effect_name: "Access Issue"}
    sub1 = insert(:subscription, alert_priority_type: :low, informed_entities: [%InformedEntity{stop: "70026", facility_type: :elevator}])
    sub2 = insert(:subscription, alert_priority_type: :medium, informed_entities: [%InformedEntity{stop: "70026", facility_type: :elevator}])
    sub3 = insert(:subscription, alert_priority_type: :high, informed_entities: [%InformedEntity{stop: "70026", facility_type: :elevator}])

    assert {:ok, [sub1, sub2, sub3], alert} == SeverityFilter.filter({:ok, [sub1, sub2, sub3], alert})
  end

  test "will send based off highest priority in alert" do
    alert = %Alert{informed_entities: [%InformedEntity{route_type: 1}, %InformedEntity{route_type: 1, route: "Red"}], severity: :minor, effect_name: "Delay"}
    sub = insert(:subscription, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 1, route: "Red"}])

    assert {:ok, [sub], alert} == SeverityFilter.filter({:ok, [sub], alert})
  end
end
