defmodule ConciergeSite.Subscriptions.DisplayInfo do
  @moduledoc """
  module for gathering info to display subscription info
  in a meaningful way to a user.
  """

  alias AlertProcessor.{ApiClient, Model.InformedEntity, Model.Subscription}

  @spec departure_times_for_subscriptions([Subscription.t]) :: {:ok, map} | :error
  def departure_times_for_subscriptions(subscriptions) do
    with {:ok, stops} <- parse_station_list(subscriptions),
        {:ok, schedules, trips} <- ApiClient.schedules(stops),
        {schedules, trip_names_map} <- map_trip_names(schedules, trips) do
      {:ok, map_trip_departure_times(schedules, trip_names_map)}
    else
      _ -> {:ok, %{}}
    end
  end

  defp parse_station_list(subscriptions) do
    stops =
      subscriptions
      |> Enum.flat_map(fn(subscription) ->
        for informed_entity <- subscription.informed_entities, InformedEntity.entity_type(informed_entity) == :stop do
          informed_entity.stop
        end
      end)
      |> Enum.uniq()

    case stops do
      [] -> :error
      _ -> {:ok, stops}
    end
  end

  defp map_trip_names(schedules, trips) do
    {schedules, Map.new(trips, fn(%{"id" => id, "attributes" => %{"name" => name}}) -> {id, name} end)}
  end

  defp map_trip_departure_times(schedules, trip_names_map) do
    schedules_map = Enum.group_by(schedules, fn(%{"relationships" => %{"trip" => %{"data" => %{"id" => id}}}}) -> id end)

    for {_id, schedules} <- schedules_map, Enum.count(schedules) > 1, into: %{} do
      [departure_schedule | _] = Enum.sort_by(schedules, fn(%{"attributes" => %{"departure_time" => departure_timestamp}}) -> departure_timestamp end)
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

      {Map.get(trip_names_map, trip_id), departure_timestamp}
    end
  end
end
