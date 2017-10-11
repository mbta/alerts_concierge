defmodule ConciergeSite.Subscriptions.FerryParams do
  @moduledoc """
  Functions for processing user input during the create ferry subscription flow
  """

  import ConciergeSite.Subscriptions.ParamsValidator
  alias AlertProcessor.{Model.Subscription, ServiceInfoCache, Subscription.FerryMapper}

  @spec validate_info_params(map) :: :ok | {:error, String.t}
  def validate_info_params(params) do
    {_, errors} =
      {params, []}
      |> validate_presence_of_origin()
      |> validate_presence_of_destination()
      |> validate_origin_destination_pair()
      |> validate_travel_day()

    case errors do
      [] ->
        :ok
      errors ->
        {:error, full_error_message_iodata(errors)}
    end
  end

  def validate_trip_params(params) do
    {_, errors} =
      {params, []}
      |> validate_presence_of_departure_trip()
      |> validate_presence_of_return_trip()

    case errors do
      [] ->
        :ok
      errors ->
        {:error, full_error_message_iodata(errors)}
    end
  end

  defp validate_presence_of_origin({params, errors}) do
    if params["origin"] == "" do
      {params, ["Origin is invalid." | errors]}
    else
      {params, errors}
    end
  end

  defp validate_presence_of_destination({params, errors}) do
    if params["destination"] == "" do
      {params, ["Destination is invalid." | errors]}
    else
      {params, errors}
    end
  end

  defp validate_origin_destination_pair({params, errors}) do
    %{"origin" => origin, "destination" => destination, "relevant_days" => relevant_days} = params
    case FerryMapper.map_trip_options(origin, destination, String.to_existing_atom(relevant_days)) do
      {:ok, _} ->
        {params, errors}
      _ ->
        {params, ["There are no scheduled trips between your origin and destination on the days you have selected. Please choose a new origin, destination, or travel day." | errors]}
    end
  end

  defp validate_travel_day({params, errors}) do
    if Enum.member?(["weekday", "saturday", "sunday"], String.downcase(params["relevant_days"])) do
      {params, errors}
    else
      {params, ["A travel day option must be selected." | errors]}
    end
  end

  defp validate_presence_of_departure_trip({params, errors}) do
    case params["trips"] do
      [_h | _t] ->
        {params, errors}
      _ ->
        {params, ["Please select at least one trip." | errors]}
    end
  end

  defp validate_presence_of_return_trip({%{"trip_type" => "one_way"}, _} = payload), do: payload
  defp validate_presence_of_return_trip({params, errors}) do
    case params["return_trips"] do
      [_h | _t] ->
        {params, errors}
      _ ->
        {params, ["Please select at least one return trip." | errors]}
    end
  end

  @doc """
  Transform submitted subscription params for FerryMapper
  """
  @spec prepare_for_mapper(map) :: map
  def prepare_for_mapper(%{"relevant_days" => relevant_days, "origin" => origin, "destination" => destination, "trips" => trips, "return_trips" => return_trips, "trip_type" => "round_trip"} = params) do
    trip_schedule_map = FerryMapper.trip_schedule_info_map(origin, destination, relevant_days)
    {departure_start, departure_end} = subscription_timestamps(trip_schedule_map, origin, destination, trips)
    {return_start, return_end} = subscription_timestamps(trip_schedule_map, destination, origin, return_trips)

    Map.merge(params, %{
      "amenities" => [],
      "departure_start" => departure_start,
      "departure_end" => departure_end,
      "relevant_days" => [relevant_days],
      "return_start" => return_start,
      "return_end" => return_end
    })
  end
  def prepare_for_mapper(%{"relevant_days" => relevant_days, "origin" => origin, "destination" => destination, "trips" => trips, "trip_type" => "one_way"} = params) do
    trip_schedule_map = FerryMapper.trip_schedule_info_map(origin, destination, relevant_days)
    {departure_start, departure_end} = subscription_timestamps(trip_schedule_map, origin, destination, trips)

    Map.merge(params, %{
      "amenities" => [],
      "departure_start" => departure_start,
      "departure_end" => departure_end,
      "relevant_days" => [relevant_days],
      "return_start" => nil,
      "return_end" => nil
    })
  end

  defp subscription_timestamps(trip_schedule_map, origin, destination, trips) do
    start_time = earliest_departure_time(trip_schedule_map, origin, trips)
    end_time = latest_departure_time(trip_schedule_map, destination, trips)
    {start_time, end_time}
  end

  defp earliest_departure_time(sm, station, trips), do: do_departure_time(sm, station, trips, &Enum.min/1)
  defp latest_departure_time(sm, station, trips), do: do_departure_time(sm, station, trips, &Enum.max/1)

  defp do_departure_time(schedule_map, station, trips, sort_order) do
    trips
    |> Enum.map(& schedule_map[{station, &1}])
    |> sort_order.()
  end

  @spec prepare_for_update_changeset(Subscription.t, map) :: {:ok, map} | :error
  def prepare_for_update_changeset(subscription, params) do
    with %{"alert_priority_type" => alert_priority_type, "trips" => trips} <- params,
         [_trip | _t] <- trips,
         {:ok, {_name, origin_id}} <- ServiceInfoCache.get_stop_by_name(subscription.origin),
         {:ok, {_name, destination_id}} <- ServiceInfoCache.get_stop_by_name(subscription.destination),
         [relevant_days] <- subscription.relevant_days,
         trip_schedule_map <- FerryMapper.trip_schedule_info_map(origin_id, destination_id, relevant_days),
         {start_time, end_time} <- subscription_timestamps(trip_schedule_map, origin_id, destination_id, trips) do
      {:ok, %{
        "alert_priority_type" => String.to_existing_atom(alert_priority_type),
        "start_time" => start_time,
        "end_time" => end_time,
        "trips" => trips
      }}
    else
      _ -> :error
    end
  end
end
