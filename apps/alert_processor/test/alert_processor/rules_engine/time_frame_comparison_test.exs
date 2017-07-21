defmodule AlertProcessor.TimeFrameComparisonTest do
  use ExUnit.Case
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

    test "doesn't match non-overlapping timeframes" do
      alert_timeframe_map = %{
        sunday: %{start: 7200, end: 14_400}
      }
      subscription_timeframe_map = %{
        saturday: %{start: 7800, end: 28_800}
      }
      refute TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end

    test "always matches if alert_timeframe_map is true" do
      alert_timeframe_map = true
      subscription_timeframe_map = %{
        sunday: %{start: 7200, end: 14_400}
      }
      assert TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end

    test "never matches if alert_timeframe_map is true" do
      alert_timeframe_map = false
      subscription_timeframe_map = %{
        sunday: %{start: 7200, end: 14_400}
      }
      refute TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end

    test "matches overlapping, overnight timeframes" do
      alert_timeframe_map = %{
        sunday: %{end: 7200, start: 14_400}
      }
      subscription_timeframe_map = %{
        sunday: %{end: 3600, start: 0}
      }
      assert TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end

    test "doesn't match non-overlapping, overnight timeframes" do
      alert_timeframe_map = %{
        sunday: %{end: 7200, start: 14_400}
      }
      subscription_timeframe_map = %{
        saturday: %{end: 7800, start: 28_800}
      }
      refute TimeFrameComparison.match?(alert_timeframe_map, subscription_timeframe_map)
    end
  end
end
