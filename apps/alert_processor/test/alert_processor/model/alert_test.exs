defmodule AlertProcessor.Model.AlertTest do
  use ExUnit.Case
  alias AlertProcessor.Model.{Alert, InformedEntity}

  @ie1 %InformedEntity{}
  @ie2 %InformedEntity{facility_type: :elevator}
  @ie3 %InformedEntity{}

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
