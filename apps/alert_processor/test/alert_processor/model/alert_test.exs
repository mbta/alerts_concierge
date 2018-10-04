defmodule AlertProcessor.Model.AlertTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias AlertProcessor.Model.{Alert, InformedEntity}

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
