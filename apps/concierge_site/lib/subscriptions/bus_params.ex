defmodule ConciergeSite.Subscriptions.BusParams do
  @moduledoc """
  Functions for processing user input during the bus subscription flow
  """
  import ConciergeSite.Subscriptions.{ParamsValidator, SubscriptionParams}
  alias AlertProcessor.Helpers.DateTimeHelper

  @spec validate_info_params(map) :: :ok | {:error, String.t}
  def validate_info_params(params) do
    {_, errors} =
      {params, []}
      |> validate_presence_of_route()
      |> validate_at_least_one_travel_day()
      |> validate_endtime_after_starttime()

    if errors == [] do
      :ok
    else
      {:error, full_error_message_iodata(errors)}
    end
  end

  defp validate_presence_of_route({params, errors}) do
    if params["route"] == "" || params["route"] == nil do
      {params, ["Route is invalid." | errors]}
    else
      {params, errors}
    end
  end

  defp validate_at_least_one_travel_day({params, errors}) do
    day_params = [params["weekday"], params["saturday"], params["sunday"]]
    if Enum.any?(day_params, &(&1 == "true")) do
      {params, errors}
    else
      {params, ["At least one travel day option must be selected." | errors]}
    end
  end

  defp validate_endtime_after_starttime({%{"return_start" => _} = params, errors}) do
    cond do
      outside_service_time_range(params["return_start"], params["return_end"]) ->
        {params, ["Start time on return trip cannot be same as or later than end time. End of service day is 03:00AM."]}
      outside_service_time_range(params["departure_start"], params["departure_end"]) ->
        {params, ["Start time on departure trip cannot be same as or later than end time. End of service day is 03:00AM."]}
      true ->
        {params, errors}
    end
  end

  defp validate_endtime_after_starttime({params, errors}) do
    if outside_service_time_range(params["departure_start"], params["departure_end"]) do
      {params, ["Start time on departure trip cannot be same as or later than end time. End of service day is 03:00AM."]}
    else
      {params, errors}
    end
  end

  defp outside_service_time_range(start_time, end_time) do
    cond do
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

  @doc """
  Transform submitted subscription params for BusMapper
  """
  @spec prepare_for_mapper(map) :: map
  def prepare_for_mapper(%{"trip_type" => "one_way"} = params) do
    translated_params = %{
      "relevant_days" => relevant_days_from_booleans(Map.take(params, ~w(weekday saturday sunday))),
      "departure_start" => DateTimeHelper.timestamp_to_utc_datetime(params["departure_start"]),
      "departure_end" => DateTimeHelper.timestamp_to_utc_datetime(params["departure_end"]),
      "return_start" => nil,
      "return_end" => nil,
      "amenities" => []
    }

    do_prepare_for_mapper(params, translated_params)
  end
  def prepare_for_mapper(%{"trip_type" => "round_trip"} = params) do
    translated_params = %{
      "relevant_days" => relevant_days_from_booleans(Map.take(params, ~w(weekday saturday sunday))),
      "departure_start" => DateTimeHelper.timestamp_to_utc_datetime(params["departure_start"]),
      "departure_end" => DateTimeHelper.timestamp_to_utc_datetime(params["departure_end"]),
      "return_start" => DateTimeHelper.timestamp_to_utc_datetime(params["return_start"]),
      "return_end" => DateTimeHelper.timestamp_to_utc_datetime(params["return_end"]),
      "amenities" => []
    }

    do_prepare_for_mapper(params, translated_params)
  end

  def do_prepare_for_mapper(params, translated_params) do
    params
    |> Map.take(["alert_priority_type", "departure_end", "departure_start", "return_start", "return_end", "route"])
    |> Map.merge(translated_params)
  end
end
