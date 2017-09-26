defmodule AlertProcessor.Model.AlertTest do
  use ExUnit.Case
  alias AlertProcessor.Model.{Alert, InformedEntity}

  @ie1 %InformedEntity{route_type: 0, route: nil}
  @ie2 %InformedEntity{facility_type: :elevator}
  @ie3 %InformedEntity{route_type: 0, route: "Red"}
  @ie4 %InformedEntity{stop: "place-nqncy"}

  describe "severity_value/1" do
    test "Systemwide" do
      alert = %Alert{severity: :minor, informed_entities: [@ie1]}
      assert Alert.severity_value(alert) == 1
    end

    test "Facility" do
      alert = %Alert{severity: :minor, informed_entities: [@ie4]}
      assert Alert.severity_value(alert) == 1
    end

    test "Other route" do
      alert = %Alert{severity: :minor, informed_entities: [@ie3]}
      assert Alert.severity_value(alert) == 1
    end

    test "Effect name overrides default severity" do
      alert = %Alert{severity: :minor, effect_name: "Shuttle", informed_entities: [@ie3]}
      assert Alert.severity_value(alert) == 3
    end

    test "Extreme severity" do
      alert = %Alert{severity: :extreme, informed_entities: [@ie3]}
      assert Alert.severity_value(alert) == 4
    end
  end

  describe "facility_alert?/1" do
    test "it returns {:ok, true} if any informed_entity has a facility_type" do
      alert = %Alert{informed_entities: [@ie1, @ie2, @ie3]}
      assert {:ok, true} == Alert.facility_alert?(alert)
    end

    test "it returns {:ok, false} if no informed_entity has a facility_type" do
      alert = %Alert{informed_entities: [@ie1, @ie3]}
      assert {:ok, false} == Alert.facility_alert?(alert)
    end

    test "it returns {:ok, false} if no informed_entities" do
      alert = %Alert{informed_entities: []}
      assert {:ok, false} == Alert.facility_alert?(alert)
    end
  end
end
