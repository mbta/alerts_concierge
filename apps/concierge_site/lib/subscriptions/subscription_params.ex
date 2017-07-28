defmodule ConciergeSite.Subscriptions.SubscriptionParams do
  @moduledoc """
  Functions for processing user input during the subscription flow
  """
  alias AlertProcessor.Helpers.DateTimeHelper

  @spec prepare_for_update_changeset(map) :: map
  def prepare_for_update_changeset(params) do
    relevant_days =
      params
      |> Map.take(~w(saturday sunday weekday))
      |> relevant_days_from_booleans()
      |> Enum.map(&String.to_existing_atom/1)

    %{"alert_priority_type" => String.to_existing_atom(params["alert_priority_type"]),
      "relevant_days" => relevant_days,
      "end_time" => DateTimeHelper.timestamp_to_utc_datetime(params["departure_end"]),
      "start_time" => DateTimeHelper.timestamp_to_utc_datetime(params["departure_start"])}
  end

  def relevant_days_from_booleans(day_map) do
    day_map
    |> Enum.filter(fn {_day, bool} -> bool == "true" end)
    |> Enum.map(fn {day, _bool} -> day end)
  end

  @spec outside_service_time_range(String.t, String.t) :: boolean()
  def outside_service_time_range(start_time, end_time) do
    cond do
      end_time > start_time and end_time > "00:00:00" and end_time <= "03:00:00" ->
        false
      end_time > start_time and start_time >= "03:00:00" ->
        false
      start_time >= "03:00:00" and end_time >= "00:00:00" and end_time < "03:00:00" ->
        false
      true ->
        true
    end
  end
end
