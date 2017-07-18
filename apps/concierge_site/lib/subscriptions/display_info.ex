defmodule ConciergeSite.Subscriptions.DisplayInfo do
  @moduledoc """
  module for gathering info to display subscription info
  in a meaningful way to a user.
  """

  alias AlertProcessor.{ApiClient, Helpers.DateTimeHelper, Model.InformedEntity, Model.Subscription, ServiceInfoCache}

  @spec departure_times_for_subscriptions([Subscription.t], Date.t | nil) :: {:ok, map} | :error
  def departure_times_for_subscriptions(subscriptions, selected_date \\ nil) do
    with {:ok, stops, relevant_days} <- parse_subscription_stops_and_relevant_days(subscriptions),
        {schedules, trips} <- fetch_schedule_info(stops, relevant_days, selected_date),
        {schedules, trip_names_map} <- map_trip_names(schedules, trips) do
      {:ok, map_trip_departure_times(schedules, trip_names_map)}
    else
      _ -> {:ok, %{}}
    end
  end

  defp parse_subscription_stops_and_relevant_days(subscriptions) do
    stops =
      subscriptions
      |> Enum.filter(& Enum.member?([:commuter_rail, :ferry], &1.type))
      |> Enum.flat_map(fn(subscription) ->
        for informed_entity <- subscription.informed_entities, InformedEntity.entity_type(informed_entity) == :stop do
          informed_entity.stop
        end
      end)
      |> Enum.uniq()

    relevant_days =
      subscriptions
      |> Enum.flat_map(& &1.relevant_days)
      |> Enum.uniq()

    case stops do
      [] -> :error
      _ -> {:ok, stops, relevant_days}
    end
  end

  defp fetch_schedule_info(stops, relevant_days, selected_date) do
    Enum.reduce(relevant_days, {[], []}, fn(relevant_day, {previous_schedules, previous_trips}) ->
      relevant_date = selected_date || DateTimeHelper.determine_date(relevant_day, Date.utc_today())
      {:ok, schedules, trips} = ApiClient.schedules_for_stops(stops, relevant_date)
      {previous_schedules ++ schedules, previous_trips ++ trips}
    end)
  end

  defp map_trip_names(schedules, trips) do
    name_map =
      for %{"id" => id, "attributes" => %{"name" => name}} <- trips, into: %{} do
        case ServiceInfoCache.get_generalized_trip_id(id) do
          {:ok, nil} -> {id, name}
          {:ok, generalized_trip_id} -> {id, generalized_trip_id}
        end
      end

    {schedules, name_map}
  end

  defp map_trip_departure_times(schedules, trip_names_map) do
    schedules_map = Enum.group_by(schedules, & &1["relationships"]["trip"]["data"]["id"])

    for {_id, schedules} <- schedules_map, Enum.count(schedules) > 1, into: %{} do
      [departure_schedule | _] = Enum.sort_by(schedules, & &1["attributes"]["departure_time"])
      %{
        "attributes" => %{
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
      departure_timestamp =
        departure_timestamp
        |> NaiveDateTime.from_iso8601!
        |> NaiveDateTime.to_time()
        |> Calendar.Strftime.strftime!("%l:%M%P")
        |> String.trim()

      {Map.get(trip_names_map, trip_id, trip_id), departure_timestamp}
    end
  end
end
