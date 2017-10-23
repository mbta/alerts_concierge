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
      |> validate_presence_of_routes()
      |> validate_at_least_one_travel_day()
      |> validate_endtime_after_starttime()

    if errors == [] do
      :ok
    else
      {:error, full_error_message_iodata(errors)}
    end
  end

  defp validate_presence_of_routes({params, errors}) do
    case params["routes"] do
      [_h | _t] -> {params, errors}
      _ -> {params, ["Route is invalid." | errors]}
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
    |> Map.take(["alert_priority_type", "departure_end", "departure_start", "return_start", "return_end", "routes"])
    |> Map.merge(translated_params)
  end
end
