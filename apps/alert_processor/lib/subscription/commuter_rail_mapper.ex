defmodule AlertProcessor.Subscription.CommuterRailMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  subway into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper
  alias AlertProcessor.{ApiClient, Model.Route, Model.Subscription, Model.Trip, ServiceInfoCache}

  @spec map_subscriptions(map) :: {:ok, [Subscription.subscription_info]} | :error
  def map_subscriptions(subscription_params) do
    with subscriptions <- map_timeframe(subscription_params),
         subscriptions <- map_priority(subscriptions, subscription_params),
         subscriptions <- map_type(subscriptions, :commuter_rail)
         do
      map_entities(subscriptions, subscription_params)
    end
  end

  defp map_entities(subscriptions, params) do
    with {:ok, subway_info} = ServiceInfoCache.get_commuter_rail_info(),
         %{"origin" => origin, "destination" => destination} <- params,
         routes <- Enum.filter(
           subway_info,
           fn(%Route{stop_list: stop_list}) -> List.keymember?(stop_list, origin, 1) && List.keymember?(stop_list, destination, 1)
         end),
         subscription_infos <- map_amenities(subscriptions, params),
         subscription_infos <- map_route_type(subscription_infos, routes),
         subscription_infos <- map_routes(subscription_infos, params, routes),
         subscription_infos <- map_stops(subscription_infos, params, routes),
         subscription_infos <- map_trips(subscription_infos, params),
         subscription_infos <- filter_duplicate_entities(subscription_infos) do
      {:ok, subscription_infos}
    else
      _ -> :error
    end
  end

  @doc """
  map_trip_options takes an origin, destination and relevant day and returns a list of trip options
  which consists of a trip number and the description text to be displayed to the user for selecting
  specific trips for their subscription.
  """
  @spec map_trip_options(String.t, String.t, Subscription.relevant_day) :: :error | {:ok, [Trip.t]}
  def map_trip_options(origin, destination, relevant_days, today_date \\ Calendar.Date.today!("America/New_York")) do
    {:ok, commuter_rail_info} = ServiceInfoCache.get_commuter_rail_info()
    routes = Enum.filter(commuter_rail_info, fn(%Route{stop_list: stop_list}) -> List.keymember?(stop_list, origin, 1) && List.keymember?(stop_list, destination, 1) end)
    route_ids = Enum.map(routes, &(&1.route_id))
    case routes do
      [] ->
        :error
      [route | _] ->
        direction_id = determine_direction_id(route, origin, destination)
        relevant_date = determine_date(relevant_days, today_date)

        case ApiClient.schedules(origin, destination, direction_id, route_ids, relevant_date) do
          {:ok, schedules, trips} ->
            trip_name_map = map_trip_names(trips)
            {:ok, origin_stop} = ServiceInfoCache.get_stop(origin)
            {:ok, destination_stop} = ServiceInfoCache.get_stop(destination)
            trip = %Trip{origin: origin_stop, destination: destination_stop, direction_id: direction_id}
            {:ok, map_common_trips(schedules, trip_name_map, trip)}
          _ -> :error
        end
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
    Calendar.Date.advance!(today_date, 6 - day_of_week)
  end
  defp determine_date(:sunday, today_date) do
    day_of_week = Calendar.Date.day_of_week(today_date)
    Calendar.Date.advance!(today_date, 7 - day_of_week)
  end

  defp map_trip_names(trips) do
    Map.new(trips, fn(%{"id" => id, "attributes" => %{"name" => name}}) -> {id, name} end)
  end

  defp map_common_trips([], _, _), do: :error
  defp map_common_trips(schedules, trip_names_map, trip) do
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

        %{trip | arrival_time: map_schedule_time(arrival_timestamp), departure_time: map_schedule_time(departure_timestamp), trip_number: Map.get(trip_names_map, trip_id), route: route}
      end)
    |> Enum.sort_by(fn(%Trip{departure_time: departure_time}) -> {~T[05:00:00] > departure_time, departure_time} end)
  end

  defp map_schedule_time(schedule_datetime) do
    schedule_datetime |> NaiveDateTime.from_iso8601! |> NaiveDateTime.to_time()
  end
end
