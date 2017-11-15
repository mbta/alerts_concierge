defmodule AlertProcessor.Subscription.FerryMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  ferry into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper
  alias AlertProcessor.{ApiClient, Helpers.DateTimeHelper, Model.Route, Model.Subscription, Model.Trip, ServiceInfoCache}

  defdelegate build_subscription_transaction(subscriptions, user, originator), to: AlertProcessor.Subscription.Mapper
  defdelegate build_update_subscription_transaction(subscription, user, originator), to: AlertProcessor.Subscription.Mapper

  def populate_trip_options(subscription_params), do: populate_trip_options(subscription_params, &map_trip_options/3)
  def get_trip_info(origin_id, destination_id, relevant_days, selected_trips_or_timestamp), do: get_trip_info(origin_id, destination_id, relevant_days, selected_trips_or_timestamp, &map_trip_options/3)
  def get_trip_info_from_subscription(subscription), do: get_trip_info_from_subscription(subscription, &map_trip_options/3)

  @spec map_subscriptions(map) :: {:ok, [Subscription.subscription_info]} | :error
  def map_subscriptions(subscription_params) do
    with {:ok, subscriptions} <- map_timeframe(subscription_params),
         {:ok, subscriptions} <- map_priority(subscriptions, subscription_params),
         subscriptions <- map_type(subscriptions, :ferry)
         do
      map_entities(subscriptions, subscription_params)
    else
      _ -> :error
    end
  end

  defp map_entities(subscriptions, params) do
    with {:ok, ferry_info} = ServiceInfoCache.get_ferry_info(),
         %{"origin" => origin, "destination" => destination} <- params,
         routes <- Enum.filter(
           ferry_info,
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
    {:ok, ferry_info} = ServiceInfoCache.get_ferry_info()
    routes = Enum.filter(ferry_info, fn(%Route{stop_list: stop_list}) -> List.keymember?(stop_list, origin, 1) && List.keymember?(stop_list, destination, 1) end)
    route_ids = Enum.map(routes, &(&1.route_id))
    case routes do
      [] ->
        :error
      [route | _] ->
        direction_id = determine_direction_id(route, origin, destination)
        relevant_date = DateTimeHelper.determine_date(relevant_days, today_date)

        case ApiClient.schedules(origin, destination, direction_id, route_ids, relevant_date) do
          {:ok, schedules, _trips} ->
            {:ok, origin_stop} = ServiceInfoCache.get_stop(origin)
            {:ok, destination_stop} = ServiceInfoCache.get_stop(destination)
            trip = %Trip{origin: origin_stop, destination: destination_stop, direction_id: direction_id}
            {:ok, map_common_trips(schedules, trip)}
          _ -> :error
        end
    end
  end

  defp determine_direction_id(route, origin, destination) do
    filtered_stops =
      route.stop_list
      |> Enum.filter(fn({_name, id}) -> Enum.member?([origin, destination], id) end)
      |> Enum.map(fn({_name, id}) -> id end)
    case filtered_stops do
      [^origin, ^destination] -> 1
      [^destination, ^origin] -> 0
    end
  end

  defp map_common_trips([], _), do: :error
  defp map_common_trips(schedules, trip) do
    schedules
    |> Enum.group_by(& &1["relationships"]["trip"]["data"]["id"])
    |> Enum.filter(fn({_id, schedules}) -> Enum.count(schedules) > 1 end)
    |> Enum.map(fn({_id, schedules}) ->
        [departure_schedule, arrival_schedule] = Enum.sort_by(schedules, & &1["attributes"]["departure_time"])
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
        {:ok, generalized_trip_id} = ServiceInfoCache.get_generalized_trip_id(trip_id)

        %{trip | arrival_time: map_schedule_time(arrival_timestamp), departure_time: map_schedule_time(departure_timestamp), trip_number: generalized_trip_id, route: route}
      end)
    |> Enum.sort_by(fn(%Trip{departure_time: departure_time}) -> {~T[05:00:00] > departure_time, departure_time} end)
  end

  defp map_schedule_time(schedule_datetime) do
    schedule_datetime |> NaiveDateTime.from_iso8601! |> NaiveDateTime.to_time()
  end

  @spec trip_schedule_info_map(String.t, String.t, Subscription.relevant_day) :: %{optional({Route.stop_id, Trip.id}) => DateTime.t}
  def trip_schedule_info_map(origin, destination, relevant_days, today_date \\ Calendar.Date.today!("America/New_York")) do
    relevant_date = DateTimeHelper.determine_date(relevant_days, today_date)
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

      time = departure_time |> String.slice(11..18) |> Time.from_iso8601!
      {{includes_info[stop_id], includes_info[trip_id]}, time}
    end
  end
end
