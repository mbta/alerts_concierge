defmodule AlertProcessor.Model.AlertTest do
  use ExUnit.Case, async: true
  alias AlertProcessor.Model.{Alert, InformedEntity}

  @ie1 %InformedEntity{route_type: 0, route: nil}
  @ie2 %InformedEntity{stop: "place-nqnce", facility_type: :elevator}
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
    test "it returns true if any informed_entity has a facility_type" do
      alert = %Alert{informed_entities: [@ie1, @ie2, @ie3]}
      assert true == Alert.facility_alert?(alert)
    end

    test "it returns false if no informed_entity has a facility_type" do
      alert = %Alert{informed_entities: [@ie1, @ie3]}
      assert false == Alert.facility_alert?(alert)
    end

    test "it returns false if no informed_entities" do
      alert = %Alert{informed_entities: []}
      assert false == Alert.facility_alert?(alert)
    end
  end

  describe "advance_notice_in_seconds/1" do
    test "returns the default value if less than estimated duration" do
      alert = %Alert{duration_certainty: {:estimated, 7200}}
      assert 3600 = Alert.advance_notice_in_seconds(alert)
    end

    test "returns the estimated duration if lower than the default minor value" do
      alert = %Alert{duration_certainty: {:estimated, 1800}}
      assert 1800 = Alert.advance_notice_in_seconds(alert)
    end
  end

  describe "commuter_rail_alert?/1" do
    test "with commuter_rail informed_entities" do
      ies = [
        %InformedEntity{
          route_type: 2
        }
      ]

      assert Alert.commuter_rail_alert?(%Alert{informed_entities: ies})
    end

    test "without commuter_rail informed_entities" do
      ies = [
        %InformedEntity{
          route_type: 1
        }
      ]

      refute Alert.commuter_rail_alert?(%Alert{informed_entities: ies})
    end

    test "invalid data for informed_entities" do
      refute Alert.commuter_rail_alert?(%Alert{informed_entities: nil})
    end
  end
end
