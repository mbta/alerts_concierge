defmodule AlertProcessor.TimeFrameComparisonTest do
  use ExUnit.Case, async: true
  alias AlertProcessor.TimeFrameComparison

  describe "match?" do
    test "matches overlapping timeframes" do
      alert_timeframe_map = %{
        sunday: %{start: 7200, end: 14_400}
      }

      subscription_timeframe_map = %{
        sunday: %{start: 7800, end: 28_800}
      }

      assert TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end

    test "matches un-ending active period" do
      alert_timeframe_map = true

      subscription_timeframe_map = %{
        sunday: %{start: 7800, end: 28_800}
      }

      assert TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end

    test "does not match never-starting active period" do
      alert_timeframe_map = false

      subscription_timeframe_map = %{
        sunday: %{start: 7800, end: 28_800}
      }

      refute TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end

    test "doesn't match non-overlapping timeframes" do
      alert_timeframe_map = %{
        sunday: %{start: 7200, end: 14_400}
      }

      subscription_timeframe_map = %{
        saturday: %{start: 7800, end: 28_800}
      }

      refute TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end

    test "matches overlapping, overnight timeframes" do
      alert_timeframe_map = %{
        saturday: %{end: 86_399, start: 14_400},
        sunday: %{end: 7200, start: 0}
      }

      subscription_timeframe_map = %{
        saturday: %{end: 86_399, start: 57_600},
        sunday: %{end: 3600, start: 0}
      }

      assert TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end

    test "matches overlapping, overnight timeframes for weekdays" do
      alert_timeframe_map = %{
        friday: %{end: 86_399, start: 14_400},
        saturday: %{end: 7200, start: 0}
      }

      subscription_timeframe_map = %{
        monday: %{end: 86_399, start: 57_600},
        tuesday: %{end: 3600, start: 57_600},
        wednesday: %{end: 3600, start: 57_600},
        thursday: %{end: 3600, start: 57_600},
        friday: %{end: 3600, start: 57_600},
        saturday: %{end: 3600, start: 0}
      }

      assert TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end

    test "doesn't match non-overlapping, overnight timeframes" do
      alert_timeframe_map = %{
        saturday: %{end: 86_399, start: 14_400},
        sunday: %{end: 7200, start: 0}
      }

      subscription_timeframe_map = %{
        sunday: %{end: 86_399, start: 14_400},
        monday: %{end: 7200, start: 0}
      }

      refute TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end
  end
end
