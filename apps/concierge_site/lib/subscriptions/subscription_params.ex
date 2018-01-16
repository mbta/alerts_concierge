defmodule ConciergeSite.Subscriptions.SubscriptionParams do
  @moduledoc """
  Functions for processing user input during the subscription flow
  """
  import ConciergeSite.Subscriptions.ParamsValidator

  @spec prepare_for_update_changeset(map) :: {:ok, map} | {:error, iodata}
  def prepare_for_update_changeset(params) do
    {params, errors} = validate_endtime_after_starttime({params, []})

    if errors == [] do
      relevant_days =
        params
        |> Map.take(~w(saturday sunday weekday))
        |> relevant_days_from_booleans()
        |> Enum.map(&String.to_existing_atom/1)

      {:ok, %{"alert_priority_type" => String.to_existing_atom(params["alert_priority_type"]),
        "relevant_days" => relevant_days,
        "end_time" => params["departure_end"],
        "start_time" => params["departure_start"]}}
    else
      {:error, full_error_message_iodata(errors)}
    end
  end

  def relevant_days_from_booleans(day_map) do
    day_map
    |> Enum.filter(fn {_day, bool} -> bool == "true" end)
    |> Enum.map(fn {day, _bool} -> day end)
  end

  @spec outside_service_time_range(String.t, String.t) :: boolean
  def outside_service_time_range(start_time, end_time) do
    cond do
      start_time == end_time ->
        true
      end_time > start_time and end_time > "00:00:00" and end_time <= "03:00:00" ->
        false
      end_time > start_time and start_time >= "03:00:00" ->
        false
      start_time >= "03:00:00" and end_time >= "00:00:00" and end_time <= "03:00:00" ->
        false
      true ->
        true
    end
  end

  def validate_endtime_after_starttime({%{"return_start" => _} = params, errors}) do
    errors =
      errors
      |> do_validate_endtime_after_starttime(params["return_start"], params["return_end"], "return")
      |> do_validate_endtime_after_starttime(params["departure_start"], params["departure_end"], "departure")
    {params, errors}
  end
  def validate_endtime_after_starttime({params, errors}) do
    {params, do_validate_endtime_after_starttime(errors, params["departure_start"], params["departure_end"], "departure")}
  end

  defp do_validate_endtime_after_starttime(errors, start_time, end_time, trip_type) do
    if outside_service_time_range(start_time, end_time) do
      ["Start time on", trip_type, "trip cannot be same as or later than end time. End of service day is 03:00AM." | errors]
    else
      errors
    end
  end
end
