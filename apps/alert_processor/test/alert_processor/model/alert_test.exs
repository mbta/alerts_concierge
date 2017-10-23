defmodule AlertProcessor.Model.AlertTest do
  use ExUnit.Case
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

  describe "advanced_notice_in_seconds/1 estimated minor" do
    test "returns the default minor value if less than estimated duration" do
      alert = %Alert{duration_certainty: "ESTIMATED", severity: :minor, estimated_duration: 7200}
      assert 3600 = Alert.advanced_notice_in_seconds(alert)
    end

    test "returns the estimated duration if lower than the default minor value" do
      alert = %Alert{duration_certainty: "ESTIMATED", severity: :minor, estimated_duration: 1800}
      assert 1800 = Alert.advanced_notice_in_seconds(alert)
    end
  end

  describe "advanced_notice_in_seconds/1 estimated moderate" do
    test "returns the default moderate value if less than estimated duration" do
      alert = %Alert{duration_certainty: "ESTIMATED", severity: :moderate, estimated_duration: 14_400}
      assert 7200 = Alert.advanced_notice_in_seconds(alert)
    end

    test "returns the estimated duration if lower than the default moderate value" do
      alert = %Alert{duration_certainty: "ESTIMATED", severity: :moderate, estimated_duration: 3600}
      assert 3600 = Alert.advanced_notice_in_seconds(alert)
    end
  end

  describe "advanced_notice_in_seconds/1 estimated severe" do
    test "returns the default severe value if less than estimated duration" do
      alert = %Alert{duration_certainty: "ESTIMATED", severity: :severe, estimated_duration: 28_800}
      assert 14_400 = Alert.advanced_notice_in_seconds(alert)
    end

    test "returns the estimated duration if lower than the default severe value" do
      alert = %Alert{duration_certainty: "ESTIMATED", severity: :severe, estimated_duration: 7200}
      assert 7200 = Alert.advanced_notice_in_seconds(alert)
    end
  end

  describe "advanced_notice_in_seconds/1 estimated extreme" do
    test "returns the default extreme value if less than estimated duration" do
      alert = %Alert{duration_certainty: "ESTIMATED", severity: :extreme, estimated_duration: 28_800}
      assert 14_400 = Alert.advanced_notice_in_seconds(alert)
    end

    test "returns the estimated duration if lower than the default extreme value" do
      alert = %Alert{duration_certainty: "ESTIMATED", severity: :extreme, estimated_duration: 3600}
      assert 3600 = Alert.advanced_notice_in_seconds(alert)
    end
  end

  describe "advanced_notice_in_seconds/1 other" do
    test "returns the default value" do
      alert = %Alert{duration_certainty: "KNOWN", severity: :minor}
      assert 86_400 = Alert.advanced_notice_in_seconds(alert)
    end
  end
end
