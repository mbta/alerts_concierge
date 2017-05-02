defmodule MbtaServer.AlertProcessor.TimeFrameComparison do
  @type timeframe_map :: %{optional(:sunday) => %{start: integer, end: integer},
                           optional(:saturday) => %{start: integer, end: integer},
                           optional(:weekday) => %{start: integer, end: integer}}


  @spec match?(boolean | map, map) :: boolean
  def match?(active_period_timeframe_map, _) when is_boolean(active_period_timeframe_map), do:
    active_period_timeframe_map
  def match?(active_period_timeframe_map, subscription_timeframe_map) do
    relevant_active_period_timeframe_map = Map.take(active_period_timeframe_map, Map.keys(subscription_timeframe_map))

    Enum.any?(relevant_active_period_timeframe_map, fn({day_of_week_atom, time_range}) ->
      timeframes_match?(time_range, subscription_timeframe_map[day_of_week_atom])
    end)
  end

  @spec timeframes_match?(%{start: integer, end: integer}, %{start: integer, end: integer}) :: boolean
  defp timeframes_match?(%{start: active_period_start, end: active_period_end}, %{start: subscription_start, end: subscription_end}) do
    active_period_range = active_period_start..active_period_end |> Enum.to_list |> MapSet.new
    subscription_range = subscription_start..subscription_end |> Enum.to_list |> MapSet.new

    !MapSet.disjoint?(active_period_range, subscription_range)
  end
end
