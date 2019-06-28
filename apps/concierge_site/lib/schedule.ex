defmodule ConciergeSite.Schedule do
  @moduledoc """
  The schedule for a route or trip.
  """
  alias AlertProcessor.{ApiClient, DayType, ExtendedTime, ServiceInfoCache}
  alias AlertProcessor.Model.{Route, Subscription, TripInfo}
  alias ConciergeSite.Schedule

  @typedoc """
  A tuple of a mode and route ID
  """
  @type route_mode_id_key :: {String.t(), String.t()}

  @type t :: %{route_mode_id_key: TripInfo.t()}

  @doc """
  Determine the direction (0 for counter to the order of the stop list, or 1 for with the order of the stop list) from some combination of a route stop list, string-formatted direction, origin, and destination.

    iex> Schedule.determine_direction_id(nil, "0", nil, nil)
    0
    iex> Schedule.determine_direction_id(nil, "1", nil, nil)
    1
    iex> stop_list = [{"Readville", "Readville", {42.238405, -71.133246}, 1}, {"Fairmount", "Fairmount", {42.253638, -71.11927}, 1}, {"Morton Street", "Morton Street", {42.280994, -71.085475}, 1}, {"Talbot Avenue", "Talbot Avenue", {42.292246, -71.07814}, 1}, {"Four Corners/Geneva", "Four Corners / Geneva", {42.305037, -71.076833}, 1}, {"Uphams Corner", "Uphams Corner", {42.31867, -71.069072}, 1}, {"Newmarket", "Newmarket", {42.326701, -71.066314}, 1}, {"South Station", "place-sstat", {42.352271, -71.055242}, 1}]
    iex> earlier_stop = "Uphams Corner"
    iex> later_stop = "Newmarket"
    iex> Schedule.determine_direction_id(stop_list, nil, later_stop, earlier_stop)
    0
    iex> Schedule.determine_direction_id(stop_list, nil, earlier_stop, later_stop)
    1
  """
  @spec determine_direction_id(
          [Route.stop()],
          String.t() | nil,
          String.t() | nil,
          String.t() | nil
        ) :: 0 | 1
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
  @spec get_schedules_for_input([String.t()], [String.t()], [String.t()], [String.t()]) ::
          Schedule.t()
  def get_schedules_for_input(legs, origins, destinations, modes) do
    return_trip = false

    [
      Enum.reverse(modes),
      Enum.reverse(legs),
      Enum.reverse(origins),
      Enum.reverse(destinations)
    ]
    |> Enum.zip()
    |> Enum.map(fn input_tuple ->
      {type, route, origin, destination} = input_tuple

      subscription = %Subscription{
        type: String.to_atom(type),
        route: route,
        origin: origin,
        destination: destination,
        return_trip: return_trip
      }

      subscription
    end)
    |> get_schedules_for_trip(return_trip)
  end

  @doc """
  Retrieve TripInfo records for a list of Subscriptions and whether or not it is a return trip.
  """
  @spec get_schedules_for_trip([Subscription.t()], boolean) :: Schedule.t()
  def get_schedules_for_trip(subscriptions, return_trip) do
    weekday_schedules =
      subscriptions
      |> get_typical_weekday_schedules(return_trip)
      |> categorize_by_weekend(false)

    weekend_schedules =
      subscriptions
      |> get_typical_weekend_schedules(return_trip)
      |> categorize_by_weekend(true)

    interleave_schedule_trips(weekday_schedules, weekend_schedules)
  end

  @spec get_typical_weekday_schedules([Subscription.t()], boolean) :: [Schedule.t()]
  defp get_typical_weekday_schedules(subscriptions, return_trip) do
    # Get schedules for 5 weekdays to figure out what the typical schedule is. We need to get enough days such that the majority of them will be non-holidays. The worst case scenario is 2 holiday days in a row, so we need 3 extra days more than this.
    5
    |> DayType.take_weekdays()
    |> typical_schedules_for_days(subscriptions, return_trip)
  end

  @spec get_typical_weekend_schedules([Subscription.t()], boolean) :: [Schedule.t()]
  defp get_typical_weekend_schedules(subscriptions, return_trip) do
    # Get schedules for 7 weekend days to figure out what the typical schedule is. We need to get enough days such that the majority of them will be non-holidays. Since Christmas day, New Years Eve, and New Years Day all run on holiday schedules, the worst case scenario is asking for a schedule on Christmas Day on a Sunday in which case there will be three weekend holiday days in a row. Therefore we need 4 extra days more than this.
    3
    |> DayType.take_saturdays()
    |> typical_schedules_for_days(subscriptions, return_trip)
  end

  @spec typical_schedules_for_days([Date.T], [Subscription.t()], boolean) :: [Schedule.t()]
  defp typical_schedules_for_days(days, subscriptions, return_trip) do
    days
    |> Enum.map(&get_schedules_for_subscriptions_and_date(subscriptions, return_trip, &1))
    |> most_common_schedule()
  end

  @spec most_common_schedule([map]) :: [Schedule.t()]
  defp most_common_schedule(daily_schedules) do
    {most_common_schedule, _count} =
      daily_schedules
      |> Enum.reduce(%{}, fn schedule, acc -> Map.update(acc, schedule, 1, &(&1 + 1)) end)
      |> Enum.sort_by(&elem(&1, 1))
      |> List.last()

    most_common_schedule
  end

  @spec get_schedules_for_subscriptions_and_date([Subscription.t()], boolean, Date.t()) :: [
          Schedule.t()
        ]
  defp get_schedules_for_subscriptions_and_date(subscriptions, return_trip, date) do
    subscriptions
    |> Enum.filter(&(&1.return_trip == return_trip))
    |> Enum.reduce(%{}, fn %{type: type, route: route, origin: origin, destination: destination},
                           acc ->
      case type do
        :subway ->
          acc

        :bus ->
          acc

        _ ->
          Map.put(
            acc,
            {Atom.to_string(type), route},
            get_schedule(route, origin, destination, date)
          )
      end
    end)
  end

  @spec get_schedule(String.t(), String.t(), String.t(), Date.t()) :: [TripInfo.t()]
  defp get_schedule(route_id, origin, destination, date) do
    with {:ok, route} <- ServiceInfoCache.get_route(route_id),
         direction_id <- determine_direction_id(route.stop_list, nil, origin, destination),
         {:ok, origin_stop} <- ServiceInfoCache.get_stop(origin),
         {:ok, destination_stop} <- ServiceInfoCache.get_stop(destination),
         trip <- %TripInfo{
           origin: origin_stop,
           destination: destination_stop,
           direction_id: direction_id
         } do
      case ApiClient.schedules(
             origin,
             destination,
             direction_id,
             [route.route_id],
             date
           ) do
        {:ok, schedules, trips} ->
          map_common_trips(schedules, map_trip_names(trips), trip, date)

        {:ok, _} ->
          []

        {:error, _} ->
          []
      end
    end
  end

  @spec map_trip_names([map]) :: map
  defp map_trip_names(trips) do
    Map.new(trips, &map_trip_name/1)
  end

  @spec map_trip_name(map) :: tuple
  defp map_trip_name(%{"type" => "trip", "id" => id, "attributes" => %{"name" => name}}),
    do: {id, name}

  defp map_trip_name(_), do: {nil, nil}

  @spec map_common_trips([map], map, map, Date.t()) :: [TripInfo.t()] | :error
  defp map_common_trips([], _, _, _), do: :error

  defp map_common_trips(schedules, trip_names_map, trip, date) do
    schedules
    |> Enum.group_by(fn %{"relationships" => %{"trip" => %{"data" => %{"id" => id}}}} -> id end)
    |> Enum.filter(fn {_id, schedules} -> Enum.count(schedules) > 1 end)
    |> Enum.map(fn {_id, schedules} ->
      [departure_schedule, arrival_schedule | _] =
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

      arrival_datetime = NaiveDateTime.from_iso8601!(arrival_timestamp)
      departure_datetime = NaiveDateTime.from_iso8601!(departure_timestamp)

      {:ok, arrival_extended_time} = ExtendedTime.new(arrival_datetime, date)
      {:ok, departure_extended_time} = ExtendedTime.new(departure_datetime, date)

      %{
        trip
        | arrival_time: NaiveDateTime.to_time(arrival_datetime),
          departure_time: NaiveDateTime.to_time(departure_datetime),
          arrival_extended_time: arrival_extended_time,
          departure_extended_time: departure_extended_time,
          trip_number: Map.get(trip_names_map, trip_id),
          route: route
      }
    end)
    |> Enum.sort(&by_departure_extended_time/2)
  end

  @spec categorize_by_weekend([Schedule.t()], boolean) :: Schedule.t()
  defp categorize_by_weekend(schedules, weekend?) do
    schedules
    |> Map.new(fn {key, trips} -> {key, trips |> Enum.map(&Map.put(&1, :weekend?, weekend?))} end)
  end

  @spec interleave_schedule_trips(Schedule.t(), Schedule.t()) :: Schedule.t()
  defp interleave_schedule_trips(weekday_schedules, weekend_schedules) do
    # weekday_schedules and weekend_schedules should contain the same keys
    weekday_schedules
    |> Map.new(fn {key, _} ->
      {
        key,
        merge_and_sort_trips(weekday_schedules[key], weekend_schedules[key])
      }
    end)
  end

  @spec merge_and_sort_trips([TripInfo.t()], [TripInfo.t()]) :: [TripInfo.t()]
  defp merge_and_sort_trips(weekday_trips, weekend_trips) do
    (weekday_trips ++ weekend_trips)
    |> Enum.sort(&by_departure_extended_time/2)
  end

  @spec by_departure_extended_time(TripInfo.t(), TripInfo.t()) :: boolean
  defp by_departure_extended_time(
         %TripInfo{departure_extended_time: departure_extended_time_a},
         %TripInfo{departure_extended_time: departure_extended_time_b}
       ),
       do:
         ExtendedTime.compare(departure_extended_time_a, departure_extended_time_b) in [:lt, :eq]
end
