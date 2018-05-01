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
    {subscription, informed_entity, new_match_report()}
    |> route_type_match?()
    |> direction_id_match?()
    |> route_match?()
    |> stop_match?()
    |> activities_match?()
    |> all_match?()
  end

  defp new_match_report() do
    %{route_type_match?: false,
      route_match?: false,
      direction_id_match?: false,
      stop_match?: false,
      activities_match?: false}
  end

  defp route_type_match?({subscription, %{route_type: nil} = informed_entity, match_report}) do
    updated_match_report = Map.put(match_report, :route_type_match?, true)
    {subscription, informed_entity, updated_match_report}
  end

  defp route_type_match?({%{route_type: nil} = subscription, informed_entity, match_report}) do
    updated_match_report = Map.put(match_report, :route_type_match?, true)
    {subscription, informed_entity, updated_match_report}
  end

  defp route_type_match?({subscription, informed_entity, match_report}) do
    route_type_match? = subscription.route_type == informed_entity.route_type
    updated_match_report = Map.put(match_report, :route_type_match?, route_type_match?)
    {subscription, informed_entity, updated_match_report}
  end

  defp direction_id_match?({subscription, %{direction_id: nil} = informed_entity, match_report}) do
    updated_match_report = Map.put(match_report, :direction_id_match?, true)
    {subscription, informed_entity, updated_match_report}
  end

  defp direction_id_match?({%{direction_id: nil} = subscription, informed_entity, match_report}) do
    updated_match_report = Map.put(match_report, :direction_id_match?, true)
    {subscription, informed_entity, updated_match_report}
  end

  defp direction_id_match?({subscription, informed_entity, match_report}) do
    direction_id_match? = subscription.direction_id == informed_entity.direction_id
    updated_match_report = Map.put(match_report, :direction_id_match?, direction_id_match?)
    {subscription, informed_entity, updated_match_report}
  end

  defp route_match?({subscription, %{route: nil} = informed_entity, match_report}) do
    updated_match_report = Map.put(match_report, :route_match?, true)
    {subscription, informed_entity, updated_match_report}
  end

  defp route_match?({%{route: nil} = subscription, informed_entity, match_report}) do
    updated_match_report = Map.put(match_report, :route_match?, true)
    {subscription, informed_entity, updated_match_report}
  end

  defp route_match?({subscription, informed_entity, match_report}) do
    route_match? = subscription.route == informed_entity.route
    updated_match_report = Map.put(match_report, :route_match?, route_match?)
    {subscription, informed_entity, updated_match_report}
  end

  defp stop_match?({subscription, %{stop: nil} = informed_entity, match_report}) do
    updated_match_report =
      case {subscription.origin, subscription.destination} do
        {origin, destination} when not is_nil(origin) and origin == destination ->
          # When origin equals destination we have what we refer to as a "stop
          # subscription". This means that this subscription doesn't care about
          # an alert's informed_entity with a nil stop. It only cares about an
          # alert if one of it's informed_entities has a stop equal to the
          # origin and destination. So, we can set `:stop_match?` to false.
          Map.put(match_report, :stop_match?, false)
        _ ->
          Map.put(match_report, :stop_match?, true)
      end
    {subscription, informed_entity, updated_match_report}
  end

  defp stop_match?({%{type: :accessibility, origin: nil} = subscription, informed_entity, match_report}) do
    stop_match? = route_stop_match?(subscription.route, informed_entity.stop)
    updated_match_report = Map.put(match_report, :stop_match?, stop_match?)
    {subscription, informed_entity, updated_match_report}
  end

  defp stop_match?({subscription, informed_entity, match_report}) do
    origin = subscription.origin
    destination = subscription.destination
    stop = informed_entity.stop
    stop_match? = origin == stop || destination == stop
    updated_match_report = Map.put(match_report, :stop_match?, stop_match?)
    {subscription, informed_entity, updated_match_report}
  end

  defp route_stop_match?(route, stop) do
    case ServiceInfoCache.get_route(route) do
      {:ok, %{stop_list: stop_list}} ->
        Enum.any?(stop_list, fn {_, route_stop_id, _, _} ->
          route_stop_id == stop
        end)
      _ -> false
    end
  end

  defp activities_match?({subscription, informed_entity, match_report}) do
    activities_match? = activities_match?(subscription, informed_entity)
    updated_match_report = Map.put(match_report, :activities_match?, activities_match?)
    {subscription, informed_entity, updated_match_report}
  end

  defp activities_match?(_subscription, %{activities: nil} = _informed_entity) do
    true
  end

  defp activities_match?(subscription, informed_entity) do
    subscription_activities = subscription_activities(subscription, informed_entity)
    Enum.any?(subscription_activities, fn subscription_activity ->
      subscription_activity in informed_entity.activities
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
        ["BOARD", "EXIT"]
      {_, origin, _, stop} when origin == stop ->
        ["BOARD"]
      {_, _, destination, stop} when destination == stop ->
        ["EXIT"]
      _ ->
        ["BOARD", "EXIT"]
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

  @spec all_match?({Subscription.t, InformedEntity.t, map}) :: boolean
  def all_match?({_subscription, _informed_entity, match_report}) do
    results = Map.values(match_report)
    Enum.all?(results, &(&1))
  end
end
