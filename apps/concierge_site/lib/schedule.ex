defmodule ConciergeSite.Schedule do
  alias AlertProcessor.ApiClient
  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.{Route, Subscription, TripInfo}

  @doc """
  Determine the direction (0 for outbound or 1 for inbound) from some combination of a route stop list, string-formatted direction, origin, and destination.

    iex> Schedule.determine_direction_id(nil, "0", nil, nil)
    0
    iex> Schedule.determine_direction_id(nil, "1", nil, nil)
    1
    iex> stop_list = [{"Readville", "Readville", {42.238405, -71.133246}, 1}, {"Fairmount", "Fairmount", {42.253638, -71.11927}, 1}, {"Morton Street", "Morton Street", {42.280994, -71.085475}, 1}, {"Talbot Avenue", "Talbot Avenue", {42.292246, -71.07814}, 1}, {"Four Corners/Geneva", "Four Corners / Geneva", {42.305037, -71.076833}, 1}, {"Uphams Corner", "Uphams Corner", {42.31867, -71.069072}, 1}, {"Newmarket", "Newmarket", {42.326701, -71.066314}, 1}, {"South Station", "place-sstat", {42.352271, -71.055242}, 1}]
    iex> inner_stop = "Newmarket"
    iex> outer_stop = "Uphams Corner"
    iex> Schedule.determine_direction_id(stop_list, nil, inner_stop, outer_stop)
    0
    iex> Schedule.determine_direction_id(stop_list, nil, outer_stop, inner_stop)
    1
  """
  @spec determine_direction_id([Route.stop], String.t | nil, String.t | nil, String.t | nil) :: 0 | 1
  def determine_direction_id(_, "0", _, _), do: 0

  def determine_direction_id(_, "1", _, _), do: 1

  def determine_direction_id(stop_list, _, origin, destination) do
    case stop_list
         |> Enum.filter(fn {_name, id, _latlong, _wheelchair} ->
           Enum.member?([origin, destination], id)
         end)
         |> Enum.map(fn {_name, id, _latlong, _wheelchair} -> id end) do
      [^origin, ^destination] -> 1
      [^destination, ^origin] -> 0
    end
  end

  @doc """
  Retrieve TripInfo records given Lists of correlated legs, origins, destination and modes.
  """
  @spec get_schedules_for_input([String.t], [String.t], [String.t], [String.t]) :: map
  def get_schedules_for_input(legs, origins, destinations, modes) do
    Enum.zip([
      Enum.reverse(modes),
      Enum.reverse(legs),
      Enum.reverse(origins),
      Enum.reverse(destinations)
    ])
    |> Enum.reduce(%{}, fn {mode, route, origin, destination}, acc ->
      case mode do
        "subway" -> acc
        "bus" -> acc
        _ -> Map.put(acc, {mode, route}, get_schedule(route, origin, destination))
      end
    end)
  end

  @doc """
  Retrieve TripInfo records for a list of Subscriptions and whether or not it is a return trip.
  """
  @spec get_schedules_for_trip([Subscription.t], boolean) :: [TripInfo.t]
  def get_schedules_for_trip(subscriptions, return_trip) do
    subscriptions
    |> Enum.filter(&(&1.return_trip == return_trip))
    |> Enum.reduce(%{}, fn %{type: type, route: route, origin: origin, destination: destination},
                           acc ->
      case type do
        :subway -> acc
        :bus -> acc
        _ -> Map.put(acc, {Atom.to_string(type), route}, get_schedule(route, origin, destination))
      end
    end)
  end

  @spec get_schedule(String.t, String.t, String.t) :: [TripInfo.t]
  defp get_schedule(route_id, origin, destination) do
    with {:ok, route} <- ServiceInfoCache.get_route(route_id) do
      direction_id = determine_direction_id(route.stop_list, nil, origin, destination)

      {:ok, schedules, trips} =
        ApiClient.schedules(
          origin,
          destination,
          direction_id,
          [route.route_id],
          Calendar.Date.today!("America/New_York")
        )

      trip_name_map = map_trip_names(trips)
      {:ok, origin_stop} = ServiceInfoCache.get_stop(origin)
      {:ok, destination_stop} = ServiceInfoCache.get_stop(destination)

      trip = %TripInfo{ 
        origin: origin_stop,
        destination: destination_stop,
        direction_id: direction_id
      }

      map_common_trips(schedules, trip_name_map, trip)
    end
  end

  @spec map_trip_names([map]) :: map
  defp map_trip_names(trips) do
    Map.new(trips, &map_trip_name/1)
  end

  defp map_trip_name(%{"type" => "trip", "id" => id, "attributes" => %{"name" => name}}),
    do: {id, name}

  defp map_trip_name(_), do: {nil, nil}

  defp map_common_trips([], _, _), do: :error

  defp map_common_trips(schedules, trip_names_map, trip) do
    schedules
    |> Enum.group_by(fn %{"relationships" => %{"trip" => %{"data" => %{"id" => id}}}} -> id end)
    |> Enum.filter(fn {_id, schedules} -> Enum.count(schedules) > 1 end)
    |> Enum.map(fn {_id, schedules} ->
      [departure_schedule, arrival_schedule] =
        Enum.sort_by(schedules, fn %{"attributes" => %{"departure_time" => departure_timestamp}} ->
          departure_timestamp
        end)

      %{
        "attributes" => %{
          "departure_time" => departure_timestamp
        },
        "relationships" => %{
          "trip" => %{
            "data" => %{
              "id" => trip_id
            }
          },
          "route" => %{
            "data" => %{
              "id" => route_id
            }
          }
        }
      } = departure_schedule

      %{"attributes" => %{"arrival_time" => arrival_timestamp}} = arrival_schedule
      {:ok, route} = ServiceInfoCache.get_route(route_id)

      %{
        trip
        | arrival_time: map_schedule_time(arrival_timestamp),
          departure_time: map_schedule_time(departure_timestamp),
          trip_number: Map.get(trip_names_map, trip_id),
          route: route
      }
    end)
    |> Enum.sort_by(fn %TripInfo{departure_time: departure_time} ->
      {~T[05:00:00] > departure_time, departure_time}
    end)
  end

  defp map_schedule_time(schedule_datetime) do
    schedule_datetime |> NaiveDateTime.from_iso8601!() |> NaiveDateTime.to_time()
  end

end
