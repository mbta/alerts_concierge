defmodule ConciergeSite.Subscriptions.FerryParams do
  @moduledoc """
  Functions for processing user input during the create ferry subscription flow
  """

  import ConciergeSite.Subscriptions.ParamsValidator
  alias AlertProcessor.{ApiClient, Helpers.DateTimeHelper, ServiceInfoCache, Subscription.FerryMapper}

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
        {params, ["Please select a valid origin and destination combination." | errors]}
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
    trip_schedule_map = trip_schedule_info_map(origin, destination, relevant_days)
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
    trip_schedule_map = trip_schedule_info_map(origin, destination, relevant_days)
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

  defp trip_schedule_info_map(origin, destination, relevant_days) do
    relevant_date = DateTimeHelper.determine_date(relevant_days, Date.utc_today())
    {:ok, data, includes} = ApiClient.schedules(origin, destination, nil, [], relevant_date)
    includes_info =
      for include <- includes, into: %{} do
        case include do
          %{"type" => "trip", "id" => id} ->
            {:ok, generalized_trip_id} = ServiceInfoCache.get_generalized_trip_id(id)
            {id, generalized_trip_id}
          %{"type" => "stop", "relationships" => %{"parent_station" => %{"data" => parent_station}}, "id" => id} ->
            case {id, parent_station} do
              {^origin, nil} ->
                {origin, origin}
              {^destination, nil} ->
                {destination, destination}
              {id, %{"id" => parent_station_id}} ->
                {id, parent_station_id}
            end
        end
      end

    for schedule <- data, into: %{} do
      %{
        "attributes" => %{
          "departure_time" => departure_time
        },
        "relationships" => %{
          "trip" => %{
            "data" => %{
              "id" => trip_id
            }
          },
          "stop" => %{
            "data" => %{
              "id" => stop_id
            }
          }
        }
      } = schedule

      {{includes_info[stop_id], includes_info[trip_id]}, departure_time}
    end
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
    |> NaiveDateTime.from_iso8601!()
    |> Calendar.Strftime.strftime!("%H:%M:%S")
  end
end
