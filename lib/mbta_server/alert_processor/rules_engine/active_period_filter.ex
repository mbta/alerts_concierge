defmodule MbtaServer.AlertProcessor.ActivePeriodFilter do
  @moduledoc """
  Filter subscriptions based on matching an active period in an alert
  """

  import Ecto.Query
  alias MbtaServer.AlertProcessor.Model.{Alert, Subscription}
  alias MbtaServer.AlertProcessor.Helpers.DateTimeHelper

  @doc """
  filter/1 takes a tuple including a subquery which represents the remaining
  subscriptions to be considered and an alert and returns the now remaining
  subscriptions to be considered in the form of an ecto queryable which have
  been matched based on the active period(s) in the alert.
  """
  @spec filter({:ok, Ecto.Queryable.t, Alert.t}) :: {:ok, Ecto.Queryable.t, Alert.t}
  def filter({:ok, previous_query, %Alert{active_period: active_periods} = alert}) do
    subscriptions = MbtaServer.Repo.all(from s in subquery(previous_query))
    subscription_timeframe_maps =
      subscriptions
      |> Enum.reduce(%{}, fn(x, acc) ->
        Map.put(acc, x.id, Subscription.timeframe_map(x))
      end)

    {_filtered_subscriptions, matched_subscriptions} =
      active_periods
      |> Enum.reduce({subscriptions, []}, fn(active_period, {pending_approval_subscriptions, previously_matched}) ->
        active_period_timeframe_map = active_period_timeframe_map(active_period)

        {matched, unmatched} = pending_approval_subscriptions |> Enum.split_with(fn(subscription) ->
          compare_with_subscriptions(active_period_timeframe_map, Map.get(subscription_timeframe_maps, subscription.id))
        end)
        {unmatched, matched ++ previously_matched}
      end)

    query = from s in Subscription,
      where: s.id in ^Enum.map(matched_subscriptions, & &1.id)

    {:ok, query, alert}
  end

  @spec compare_with_subscriptions(true | map, map) :: boolean
  defp compare_with_subscriptions(true, _), do: true
  defp compare_with_subscriptions(active_period_timeframe_map, subscription_timeframe_map) do
    relevant_active_period_timeframe_map = Map.take(active_period_timeframe_map, Map.keys(subscription_timeframe_map))

    relevant_active_period_timeframe_map |> Enum.map(fn({day_of_week_atom, time_range}) ->
      timeframes_match?(time_range, subscription_timeframe_map[day_of_week_atom])
    end) |> Enum.any?
  end

  @spec timeframes_match?(%{start: integer, end: integer}, %{start: integer, end: integer}) :: boolean
  defp timeframes_match?(%{start: active_period_start, end: active_period_end}, %{start: subscription_start, end: subscription_end}) do
    active_period_range = active_period_start..active_period_end |> Enum.to_list |> MapSet.new
    subscription_range = subscription_start..subscription_end |> Enum.to_list |> MapSet.new

    !MapSet.disjoint?(active_period_range, subscription_range)
  end

  @spec active_period_timeframe_map(%{start: DateTime.t, end: DateTime.t | nil}) :: true |
                                                                                  %{optional(:sunday) => %{start: integer, end: integer},
                                                                                    optional(:saturday) => %{start: integer, end: integer},
                                                                                    optional(:weekday) => %{start: integer, end: integer}}
  defp active_period_timeframe_map(%{start: _, end: nil}), do: true
  defp active_period_timeframe_map(%{start: period_start, end: period_end}) do
    {start_date, _} = DateTimeHelper.datetime_to_date_and_time(period_start)
    {end_date, _} = DateTimeHelper.datetime_to_date_and_time(period_end)

    if Date.compare(start_date, end_date) == :eq do
      %{start_date |> Date.day_of_week |> Subscription.relevant_day_of_week_type => %{start: 0, end: 85_399}}
    else
      {start_date_erl, start_time_erl} = DateTimeHelper.datetime_to_erl(period_start)
      {end_date_erl, end_time_erl} = DateTimeHelper.datetime_to_erl(period_end)

      period_start
      |> DateTimeHelper.gregorian_day_range(period_end)
      |> Enum.reduce(%{}, fn(gregorian_day, acc) ->
        case :calendar.gregorian_days_to_date(gregorian_day) do
          ^start_date_erl ->
            day_of_week_atom = Subscription.relevant_day_of_week_type(:calendar.day_of_the_week(start_date_erl))

            Map.put(acc, day_of_week_atom, %{start: DateTimeHelper.seconds_of_day(start_time_erl), end: 85_399})
          ^end_date_erl ->
            relevant_day_of_week_atom = Subscription.relevant_day_of_week_type(:calendar.day_of_the_week(end_date_erl))

            case Map.fetch(acc, relevant_day_of_week_atom) do
              {:ok, _} -> acc
              :error -> Map.put(acc, relevant_day_of_week_atom, %{start: 0, end: DateTimeHelper.seconds_of_day(end_time_erl)})
            end
          date_erl ->
            relevant_day_of_week_atom = Subscription.relevant_day_of_week_type(:calendar.day_of_the_week(date_erl))

            Map.put(acc, relevant_day_of_week_atom, %{start: 0, end: 85_399})
        end
      end)
    end
  end
end
