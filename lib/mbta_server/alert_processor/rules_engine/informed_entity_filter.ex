defmodule MbtaServer.AlertProcessor.InformedEntityFilter do
  @moduledoc """
  Filter users based on informed entity records tied to subscriptions.
  """

  import Ecto.Query
  alias MbtaServer.Repo
  alias MbtaServer.AlertProcessor.Model.{Alert, InformedEntity, Subscription}

  @doc """
  filter/1 takes a tuple of the remaining users to be considered and
  an alert and returns the now remaining users to be considered
  which have a matching subscription based on informed endtities and
  an alert to pass through to the next filter. Otherwise the flow is
  shortcircuited if the user id list provided is missing or empty.
  """
  @spec filter({:ok, nil | [String.t], Alert.t}) :: {:ok, [String.t], Alert.t} | {:error, :empty, Alert.t}
  def filter({:ok, nil, %Alert{} = alert}), do: {:error, :empty, alert}
  def filter({:ok, [], %Alert{} = alert}), do: {:error, :empty, alert}
  def filter({:ok, previous_user_ids, %Alert{informed_entities: informed_entities} = alert}) do
    query = Enum.reduce(informed_entities, InformedEntity, fn informed_entity, informed_entity_query ->
      informed_entity_query(informed_entity_query, struct(InformedEntity, informed_entity))
    end)

    user_ids = Repo.all(
      from q in query,
      join: s in Subscription,
      on: s.id == q.subscription_id,
      distinct: true,
      select: s.user_id
    )

    remaining_user_ids =
      previous_user_ids
      |> MapSet.new
      |> MapSet.intersection(MapSet.new(user_ids))
      |> Enum.to_list

    {:ok, remaining_user_ids, alert}
  end

  # route
  defp informed_entity_query(query, %{direction_id: nil, facility: nil, route: route, route_type: route_type, stop: nil, trip: nil}) do
    from ie in query,
      or_where: is_nil(ie.direction_id)
            and is_nil(ie.facility)
            and ie.route == ^route
            and ie.route_type == ^route_type
            and is_nil(ie.stop)
            and is_nil(ie.trip)
  end

  # route with direction
  defp informed_entity_query(query, %{direction_id: direction_id, facility: nil, route: route, route_type: route_type, stop: nil, trip: nil}) do
    from ie in query,
      or_where: ie.direction_id == ^direction_id
          and is_nil(ie.facility)
          and ie.route == ^route
          and ie.route_type == ^route_type
          and is_nil(ie.stop)
          and is_nil(ie.trip)
  end

  # stop
  defp informed_entity_query(query, %{direction_id: nil, facility: nil, route: route, route_type: route_type, stop: stop, trip: nil}) do
    from ie in query,
      or_where: is_nil(ie.direction_id)
          and is_nil(ie.facility)
          and ie.route == ^route
          and ie.route_type == ^route_type
          and ie.stop == ^stop
          and is_nil(ie.trip)
  end

  # stop with trip
  defp informed_entity_query(query, %{direction_id: nil, facility: nil, route: route, route_type: route_type, stop: stop, trip: trip}) do
    from ie in query,
      or_where: is_nil(ie.direction_id)
          and is_nil(ie.facility)
          and ie.route == ^route
          and ie.route_type == ^route_type
          and ie.stop == ^stop
          and ie.trip == ^trip
  end

  # facility
  defp informed_entity_query(query, %{direction_id: nil, facility: facility, route: nil, route_type: nil, stop: stop, trip: nil}) do
    from ie in query,
      or_where: is_nil(ie.direction_id)
          and ie.facility == ^facility
          and is_nil(ie.route)
          and is_nil(ie.route_type)
          and ie.stop == ^stop
          and is_nil(ie.trip)
  end

  # trip with direction
  defp informed_entity_query(query, %{direction_id: direction_id, facility: nil, route: route, route_type: route_type, stop: nil, trip: trip}) do
    from ie in query,
      or_where: ie.direction_id == ^direction_id
          and is_nil(ie.facility)
          and ie.route == ^route
          and ie.route_type == ^route_type
          and is_nil(ie.stop)
          and ie.trip == ^trip
  end

  # trip with stop
  defp informed_entity_query(query, %{direction_id: nil, facility: nil, route: route, route_type: route_type, stop: stop, trip: trip}) do
    from ie in query,
      or_where: is_nil(ie.direction_id)
          and is_nil(ie.facility)
          and ie.route == ^route
          and ie.route_type == ^route_type
          and ie.stop == ^stop
          and ie.trip == ^trip
  end

  # trip with stop and direction
  defp informed_entity_query(query, %{direction_id: direction_id, facility: nil, route: route, route_type: route_type, stop: stop, trip: trip}) do
    from ie in query,
      or_where: ie.direction_id == ^direction_id
          and is_nil(ie.facility)
          and ie.route == ^route
          and ie.route_type == ^route_type
          and ie.stop == ^stop
          and ie.trip == ^trip
  end
end
