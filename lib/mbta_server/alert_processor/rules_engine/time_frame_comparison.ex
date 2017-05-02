defmodule MbtaServer.AlertProcessor.TimeFrameComparison do
  @moduledoc """
  module used to compare between subscription timeframe maps
  and alert timeframe maps. maps contain keys identifying
  the day type being checked along with a start and end second
  of day to be able to create a range to check for an intersection.
  """

  @type second_of_day :: 0..86_399
  @type timeframe_map :: %{optional(:sunday) => %{start: second_of_day, end: second_of_day},
                           optional(:saturday) => %{start: second_of_day, end: second_of_day},
                           optional(:weekday) => %{start: second_of_day, end: second_of_day}}
  @type time_period :: %{start: second_of_day, end: second_of_day}


  @spec match?(boolean | timeframe_map, timeframe_map) :: boolean
  def match?(active_period_timeframe_map, _) when is_boolean(active_period_timeframe_map), do:
    active_period_timeframe_map
  def match?(active_period_timeframe_map, subscription_timeframe_map) do
    relevant_active_period_timeframe_map = Map.take(active_period_timeframe_map, Map.keys(subscription_timeframe_map))

    Enum.any?(relevant_active_period_timeframe_map, fn({day_of_week_atom, time_range}) ->
      timeframes_match?(time_range, subscription_timeframe_map[day_of_week_atom])
    end)
  end

  @spec timeframes_match?(time_period, time_period) :: boolean
  defp timeframes_match?(active_period, subscription_time_period) do
    !MapSet.disjoint?(range_map(active_period), range_map(subscription_time_period))
  end

  defp range_map(%{start: start_seconds, end: end_seconds}) do
    MapSet.new(start_seconds..end_seconds)
  end
end
