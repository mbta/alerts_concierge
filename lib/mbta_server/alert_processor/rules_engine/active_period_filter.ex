defmodule MbtaServer.AlertProcessor.ActivePeriodFilter do
  @moduledoc """
  Filter subscriptions based on matching an active period in an alert
  """

  import Ecto.Query
  alias MbtaServer.AlertProcessor.{Helpers.DateTimeHelper, Model, TimeFrameComparison}
  alias Model.{Alert, Subscription}

  @doc """
  filter/1 takes a tuple including a subquery which represents the remaining
  subscriptions to be considered and an alert and returns the now remaining
  subscriptions to be considered in the form of an ecto queryable which have
  been matched based on the active period(s) in the alert.
  """
  @spec filter({:ok, Ecto.Queryable.t, Alert.t}) :: {:ok, Ecto.Queryable.t, Alert.t}
  def filter({:ok, previous_query, %Alert{active_period: active_periods} = alert}) do
    subscriptions = MbtaServer.Repo.all(from s in subquery(previous_query))
    subscription_timeframe_maps = for x <- subscriptions, into: %{} do
      {x.id, Subscription.timeframe_map(x)}
    end

    all_matched_sub_ids = for sub <- subscriptions,
      active_period <- active_periods,
      TimeFrameComparison.match?(active_period_timeframe_map(active_period),  Map.get(subscription_timeframe_maps, sub.id)) do
      sub.id
    end

    query = from s in Subscription, where: s.id in ^Enum.uniq(all_matched_sub_ids)

    {:ok, query, alert}
  end

  @spec active_period_timeframe_map(%{start: NaiveDateTime.t, end: NaiveDateTime.t | nil}) :: true | TimeFrameComparison.timeframe_map
  defp active_period_timeframe_map(%{start: nil, end: _}), do: false
  defp active_period_timeframe_map(%{start: _, end: nil}), do: true
  defp active_period_timeframe_map(%{start: period_start, end: period_end}) do
    start_date = NaiveDateTime.to_date(period_start)
    end_date = NaiveDateTime.to_date(period_end)

    if Date.compare(start_date, end_date) == :eq do
      %{start_date |> Date.day_of_week |> Subscription.relevant_day_of_week_type => %{start: 0, end: 85_399}}
    else
      {start_date_erl, start_time_erl} = NaiveDateTime.to_erl(period_start)
      {end_date_erl, end_time_erl} = NaiveDateTime.to_erl(period_end)

      period_start
      |> DateTimeHelper.gregorian_day_range(period_end)
      |> Enum.reduce(%{}, fn(gregorian_day, acc) ->
        case :calendar.gregorian_days_to_date(gregorian_day) do
          ^start_date_erl ->
            day_of_week_atom = Subscription.relevant_day_of_week_type(:calendar.day_of_the_week(start_date_erl))

            Map.put(acc, day_of_week_atom, %{start: DateTimeHelper.seconds_of_day(start_time_erl), end: 85_399})
          ^end_date_erl ->
            relevant_day_of_week_atom = Subscription.relevant_day_of_week_type(:calendar.day_of_the_week(end_date_erl))

            Map.put_new(acc, relevant_day_of_week_atom, %{start: 0, end: DateTimeHelper.seconds_of_day(end_time_erl)})
          date_erl ->
            relevant_day_of_week_atom = Subscription.relevant_day_of_week_type(:calendar.day_of_the_week(date_erl))

            Map.put(acc, relevant_day_of_week_atom, %{start: 0, end: 85_399})
        end
      end)
    end
  end
end
