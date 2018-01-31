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
  def map_subscriptions(params) do
    route = get_route_by_id(params["route_id"])

    params = params
    |> Map.put("route", route.route_id)
    |> Map.put("direction", String.to_integer(params["direction_id"]))

    subscriptions = params
    |> create_subscriptions
    |> map_priority(params)
    |> map_type(:ferry)

    {:ok, map_entities(subscriptions, params, route)}
  end

  defp get_route_by_id(route_id) do
    {:ok, ferry_info} = ServiceInfoCache.get_ferry_info()
    Enum.find(ferry_info, & &1.route_id == route_id)
  end

  defp map_entities(subscriptions, params, route) do
    subscriptions
    |> map_route_type(route)
    |> map_route(params, route)
    |> map_stops(params, route)
    |> map_trips(params, route)
    |> filter_duplicate_entities()
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

      {{includes_info[stop_id], includes_info[trip_id]}, DateTimeHelper.time_without_zone(departure_time)}
    end
  end
end
