defmodule AlertProcessor.Subscription.CommuterRailMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  subway into the relevant subscription and informed entity structs.
  """

  alias AlertProcessor.{ApiClient, Model.Route, Model.Subscription, ServiceInfoCache}

  @type trip_number :: String.t
  @type trip_description :: iodata
  @type trip_option :: {trip_number, trip_description}

  @doc """
  map_trip_options takes an origin, destination and relevant day and returns a list of trip options
  which consists of a trip number and the description text to be displayed to the user for selecting
  specific trips for their subscription.
  """
  @spec map_trip_options(String.t, String.t, Subscription.relevant_day) :: :error | [trip_option]
  def map_trip_options(origin, destination, relevant_days, today_date \\ Calendar.Date.today!("America/New_York")) do
    {:ok, commuter_rail_info} = ServiceInfoCache.get_commuter_rail_info()
    routes = Enum.filter(commuter_rail_info, fn(%Route{stop_list: stop_list}) -> List.keymember?(stop_list, origin, 1) && List.keymember?(stop_list, destination, 1) end)
    route_ids = Enum.map(routes, &(&1.route_id))
    case routes do
      [] ->
        :error
      [route | _] ->
        direction_id = determine_direction_id(route, origin, destination)
        direction_name = Enum.at(route.direction_names, direction_id)
        relevant_date = determine_date(relevant_days, today_date)
        schedules = ApiClient.schedules(origin, destination, direction_id, route_ids, relevant_date)
        map_common_trips(schedules, origin, destination, direction_name)
    end
  end

  defp determine_direction_id(route, origin, destination) do
    case Enum.filter_map(
      route.stop_list,
      fn({_name, id}) -> Enum.member?([origin, destination], id) end,
      fn({_name, id}) -> id
    end) do
      [^origin, ^destination] -> 1
      [^destination, ^origin] -> 0
    end
  end

  defp determine_date(:weekday, today_date) do
    if Calendar.Date.day_of_week(today_date) < 6 do
      today_date
    else
      Calendar.Date.advance!(today_date, 2)
    end
  end
  defp determine_date(:saturday, today_date) do
    day_of_week = Calendar.Date.day_of_week(today_date)
    if day_of_week == 6 do
      today_date
    else
      Calendar.Date.advance!(today_date, 6 - day_of_week)
    end
  end
  defp determine_date(:sunday, today_date) do
    day_of_week = Calendar.Date.day_of_week(today_date)
    if day_of_week == 7 do
      today_date
    else
      Calendar.Date.advance!(today_date, 7 - day_of_week)
    end
  end

  defp map_common_trips([], _, _, _), do: :error
  defp map_common_trips(schedules, origin, destination, direction_name) do
    schedules
    |> Enum.group_by(fn(%{"relationships" => %{"trip" => %{"data" => %{"id" => id}}}}) -> id end)
    |> Enum.filter_map(fn({_id, schedules}) -> Enum.count(schedules) > 1 end,
      fn({_id, schedules}) ->
        [departure_schedule, arrival_schedule] = Enum.sort_by(schedules, fn(%{"attributes" => %{"departure_time" => departure_timestamp}}) -> departure_timestamp end)
        %{"attributes" => %{
          "departure_time" => departure_timestamp
          },
          "relationships" => %{
            "trip" => %{
              "data" => %{
               "id" => trip_id
              }
            }
          }
        } = departure_schedule

        %{"attributes" => %{"arrival_time" => arrival_timestamp}} = arrival_schedule
        trip_number = map_trip_id(trip_id)
        {:ok, {origin_name, ^origin}} = ServiceInfoCache.get_stop(origin)
        {:ok, {destination_name, ^destination}} = ServiceInfoCache.get_stop(destination)
        departure_time = departure_timestamp |> NaiveDateTime.from_iso8601! |> NaiveDateTime.to_time()
        {trip_number, departure_time, [trip_number, " ", direction_name, " | Departs ", origin_name, " at ", map_schedule_time(departure_timestamp), ", arrives at ", destination_name, " at ", map_schedule_time(arrival_timestamp)]}
      end)
    |> Enum.sort_by(fn({_trip_number, departure_time, _trip_description}) -> {~T[05:00:00] > departure_time, departure_time} end)
  end

  defp map_trip_id(trip_id) do
    [trip_number | _] = trip_id |> String.split("-") |> Enum.reverse()
    trip_number
  end

  defp map_schedule_time(schedule_datetime) do
    {:ok, datetime} = NaiveDateTime.from_iso8601(schedule_datetime)
    {:ok, time_string} = Calendar.Strftime.strftime(datetime, "%l:%M%P")
    String.trim(time_string)
  end
end
