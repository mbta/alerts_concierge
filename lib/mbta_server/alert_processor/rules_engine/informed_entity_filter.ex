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
  @spec filter({:ok, [String.t], Alert.t}) :: {:ok, [String.t], Alert.t}
  def filter({:ok, [], %Alert{} = alert}), do: {:ok, [], alert}
  def filter({:ok, previous_user_ids, %Alert{informed_entities: informed_entities} = alert}) do
    where_clause =
      Enum.reduce(informed_entities, false, fn(informed_entity), dynamic_query ->
        informed_entity_where_clause = informed_entity_where_clause(struct(InformedEntity, informed_entity))
        dynamic(^informed_entity_where_clause or ^dynamic_query)
      end)

    user_ids = Repo.all(
      from ie in InformedEntity,
      join: s in Subscription,
      on: s.id == ie.subscription_id,
      distinct: true,
      select: s.user_id,
      where: ^where_clause
    )

    remaining_user_ids =
      previous_user_ids
      |> MapSet.new
      |> MapSet.intersection(MapSet.new(user_ids))
      |> Enum.to_list

    {:ok, remaining_user_ids, alert}
  end

  defp informed_entity_where_clause(informed_entity) do
    informed_entity
    |> Map.take(InformedEntity.queryable_fields)
    |> Enum.reduce(true, fn({k, v}, dynamic_query) ->
      if v do
        dynamic([ie], field(ie, ^k) == ^v and ^dynamic_query)
      else
        dynamic([ie], is_nil(field(ie, ^k)) and ^dynamic_query)
      end
    end)
  end
end
