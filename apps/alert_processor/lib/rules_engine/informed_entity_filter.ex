defmodule AlertProcessor.InformedEntityFilter do
  @moduledoc """
  Filters subscriptions that should be notified of an alert.
  """

  alias AlertProcessor.Model.{Alert, InformedEntity, Subscription}
  alias AlertProcessor.ServiceInfoCache

  @doc """
  Accepts a list of subscriptions and an alert that is used to filter the
  subscriptions. Returns a list of subscriptions that should be notified about
  a given alert.

  """
  @spec filter([Subscription.t], [alert: Alert.t]) :: [Subscription.t]
  def filter(subscriptions, [alert: %Alert{} = alert]) do
    Enum.filter(subscriptions, fn(subscription) ->
      subscription_match_any?(subscription, alert.informed_entities)
    end)
  end

  @doc false
  @spec subscription_match_any?(Subscription.t, [InformedEntity.t]) :: boolean
  def subscription_match_any?(subscription, informed_entities) do
    Enum.any?(informed_entities, &subscription_match?(subscription, &1))
  end

  @doc false
  @spec subscription_match?(Subscription.t, InformedEntity.t) :: boolean
  def subscription_match?(subscription, informed_entity) do
    with true <- trip_match?(subscription, informed_entity),
         true <- route_type_match?(subscription, informed_entity),
         true <- direction_id_match?(subscription, informed_entity),
         true <- route_match?(subscription, informed_entity),
         true <- stop_match?(subscription, informed_entity),
         true <- activities_match?(subscription, informed_entity)
    do
      true
    else
      _ -> false
    end
  end

  defp trip_match?(_subscription, %{trip: nil}), do: true

  defp trip_match?(_subscription, %{schedule: nil}), do: false

  defp trip_match?(subscription, %{schedule: schedule} = _informed_entity) do
    with {:ok, trip_departure} <- trip_departure(subscription, schedule) do
      Time.compare(trip_departure, subscription.travel_start_time || subscription.start_time) in [:gt, :eq] and
        Time.compare(trip_departure, subscription.travel_end_time || subscription.end_time) in [:lt, :eq]
    else
      _ -> true
    end
  end

  defp route_type_match?(_subscription, %{route_type: nil}), do: true

  defp route_type_match?(%{route_type: nil}, _informed_entity), do: true

  defp route_type_match?(subscription, informed_entity) do
    subscription.route_type == informed_entity.route_type
  end

  defp direction_id_match?(_subscription, %{direction_id: nil}), do: true

  defp direction_id_match?(%{direction_id: nil}, _informed_entity), do: true

  defp direction_id_match?(subscription, informed_entity) do
    subscription.direction_id == informed_entity.direction_id
  end

  defp route_match?(_subscription, %{route: nil}), do: true

  defp route_match?(%{route: nil}, _informed_entity), do: true

  defp route_match?(subscription, informed_entity) do
    subscription.route == informed_entity.route
  end

  defp stop_match?(subscription, %{stop: nil, schedule: nil}) do
    case {subscription.origin, subscription.destination} do
      {origin, destination} when not is_nil(origin) and origin == destination ->
        # When origin equals destination we have what we refer to as a "stop
        # subscription". This means that this subscription doesn't care about
        # an alert's informed_entity with a nil stop. It only cares about an
        # alert if one of it's informed_entities has a stop equal to the
        # origin and destination. So, we can set `:stop_match?` to false.
        false
      _ ->
        true
    end
  end

  defp stop_match?(%{type: :accessibility, origin: nil} = subscription, informed_entity) do
    route_stop_match?(subscription.route, informed_entity.stop)
  end

  defp stop_match?(subscription, %{stop: nil, schedule: schedule})
  when not is_nil(schedule) do
    schedule_stop_match?(schedule, subscription)
  end

  defp stop_match?(subscription, informed_entity) do
    origin = subscription.origin
    destination = subscription.destination
    stop = informed_entity.stop

    origin == stop
    || destination == stop
    || in_between_stop_match?(subscription, informed_entity)
  end

  defp activities_match?(_subscription, %{activities: nil}), do: true

  defp activities_match?(subscription, informed_entity) do
    subscription_activities = subscription_activities(subscription, informed_entity)
    Enum.any?(subscription_activities, fn subscription_activity ->
      subscription_activity in informed_entity.activities
    end)
  end

  defp trip_departure(subscription, schedule) do
    case Enum.find(schedule, & &1.stop_id == subscription.origin) do
      matching_stop_event when is_map(matching_stop_event) ->
        time = time_from_scheduled_stop_event(matching_stop_event)
        {:ok, time}
      _ ->
        {:error, "Departure time not found."}
    end
  end

  defp time_from_scheduled_stop_event(scheduled_stop_event) do
    scheduled_stop_event
    |> Map.get(:departure_time)
    |> String.split("T")
    |> List.last()
    |> Time.from_iso8601!()
  end

  defp route_stop_match?(route, stop) do
    case ServiceInfoCache.get_route(route) do
      {:ok, %{stop_list: stop_list}} ->
        Enum.any?(stop_list, fn {_, route_stop_id, _, _} ->
          route_stop_id == stop
        end)
      _ ->
        false
    end
  end

  def schedule_stop_match?(schedule, subscription) do
    origin_and_destination = MapSet.new([subscription.origin, subscription.destination])
    scheduled_stops = MapSet.new(schedule, & &1.stop_id)
    MapSet.subset?(origin_and_destination, scheduled_stops)
  end

  defp in_between_stop_match?(%{type: "accessibility"}, _), do: false

  defp in_between_stop_match?(subscription, %{activities: activities, stop: stop}) do
    stop in stops_in_between(subscription, activities)
  end

  defp stops_in_between(_, nil), do: []

  defp stops_in_between(%{route: route, origin: origin, destination: destination}, activities) do
    with true <- "RIDE" in activities,
         route_filter <- %{route_id: route, stop_ids: [origin, destination]},
         {:ok, %{stop_list: stop_list}} <- ServiceInfoCache.get_route(route_filter)
    do
      stops_in_between_from_stop_list(stop_list, origin, destination)
    else
      _ -> []
    end
  end

  defp stops_in_between_from_stop_list([], _, _), do: []

  defp stops_in_between_from_stop_list(stop_list, origin, destination) do
    with {:ok, slice_range} <- slice_range(stop_list, origin, destination) do
      stop_list
      |> Enum.slice(slice_range)
      |> Enum.map(fn {_, route_stop_id, _, _} -> route_stop_id end)
    else
      _ -> []
    end
  end

  defp slice_range(stop_list, origin, destination) do
    origin_index = stop_list_index(stop_list, origin)
    destination_index = stop_list_index(stop_list, destination)
    case {origin_index, destination_index} do
      {origin, destination} when is_nil(origin) or is_nil(destination)->
        :error
      {origin, destination} when origin < destination ->
        {:ok, origin_index..destination_index}
      _ ->
        {:ok, destination_index..origin_index}
    end
  end

  defp stop_list_index(stop_list, stop) do
    Enum.find_index(stop_list, fn {_, route_stop_id, _, _} ->
      route_stop_id == stop
    end)
  end

  defp subscription_activities(subscription, informed_entity) do
    stop_related_activities(subscription, informed_entity)
    ++ facility_types_to_activities(subscription.facility_types)
  end

  defp stop_related_activities(subscription, informed_entity) do
    case {subscription.type, subscription.origin, subscription.destination, informed_entity.stop} do
      {:accessibility, _, _, _} ->
        []
      {_, nil, nil, nil} ->
        ["BOARD", "EXIT", "RIDE"]
      {_, origin, _, stop} when origin == stop ->
        ["BOARD", "RIDE"]
      {_, _, destination, stop} when destination == stop ->
        ["EXIT", "RIDE"]
      _ ->
        ["BOARD", "EXIT", "RIDE"]
    end
  end

  defp facility_types_to_activities(nil), do: []

  defp facility_types_to_activities(facility_types) do
    rules = %{
      elevator: "USING_WHEELCHAIR",
      escalator: "USING_ESCALATOR",
      parking_area: "PARK_CAR",
      bike_storage: "STORE_BIKE"
    }
    Enum.map(facility_types, &Map.get(rules, &1))
  end
end
