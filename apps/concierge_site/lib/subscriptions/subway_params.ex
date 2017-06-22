defmodule ConciergeSite.Subscriptions.SubwayParams do
  @moduledoc """
  Functions for processing user input during the create subway subscription flow
  """

  alias AlertProcessor.ApiClient

  @spec validate_info_params(map) :: :ok | {:error, String.t}
  def validate_info_params(params) do
    {_, errors} =
      {params, []}
      |> validate_presence_of_origin()
      |> validate_presence_of_destination()
      |> validate_at_least_one_travel_day()
      |> validate_station_pair()

    case errors do
      [] ->
        :ok
      errors ->
        {:error, full_error_message(errors)}
    end
  end

  defp validate_presence_of_origin({params, errors}) do
    if params["origin"] == "" do
      {params, ["origin is invalid" | errors]}
    else
      {params, errors}
    end
  end

  defp validate_presence_of_destination({params, errors}) do
    if params["destination"] == "" do
      {params, ["destination is invalid" | errors]}
    else
      {params, errors}
    end
  end

  defp validate_at_least_one_travel_day({params, errors}) do
    if {params["weekdays"], params["saturday"], params["sunday"]} == {"false", "false", "false"} do
      {params, ["At least one travel day option must be selected" | errors]}
    else
      {params, errors}
    end
  end

  defp validate_station_pair({params, errors}) do
    case map_station_schedules(params["origin"], params["destination"]) do
      {:ok, trips} ->
        [{_, origin_trip_ids}, {_, destination_trip_ids}] = trips
        if MapSet.disjoint?(origin_trip_ids, destination_trip_ids) do
          {params, ["origin and destination must be on the same line" | errors]}
        else
          {params, errors}
        end
      {:error, message} ->
        {params, [message | errors]}
    end
  end

  def map_station_schedules(origin, destination) do
    case ApiClient.subway_schedules_union(origin, destination) do
      {:ok, schedule_data, included_data} ->
        grouped_schedules = group_trips_by_stop(schedule_data)

        trips =
          group_stop_ids_by_parent_station(included_data)
          |> map_trips_to_stops(grouped_schedules)

        {:ok, trips}
      {:error, _} ->
        {:error, "there was an error fetching station data. Please try again."}
    end
  end

  defp group_trips_by_stop(schedule_data) do
    schedule_data
    |> Enum.map(fn schedule ->
      {schedule["relationships"]["stop"]["data"]["id"],
      schedule["relationships"]["trip"]["data"]["id"]}
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.into(%{})
  end

  defp group_stop_ids_by_parent_station(stop_data) do
    stop_data
    |> Enum.map(fn stop ->
      {stop["relationships"]["parent_station"]["data"]["id"], stop["id"]}
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.into([])
  end

  defp map_trips_to_stops(stop_data, grouped_schedules) do
    Enum.map(stop_data, fn stop ->
      {stop_name, stop_ids} = stop
      all_trips = Enum.flat_map(stop_ids, fn stop_id -> grouped_schedules[stop_id] end)
      {stop_name, MapSet.new(all_trips)}
    end)
  end

  defp full_error_message(errors) do
    "Please correct the following errors to proceed: #{Enum.join(errors, ", ") |> String.capitalize()}."
  end
end
