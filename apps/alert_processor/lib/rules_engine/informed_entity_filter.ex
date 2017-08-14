defmodule AlertProcessor.InformedEntityFilter do
  @moduledoc """
  Filter users based on informed entity records tied to subscriptions.
  """

  import Ecto.Query
  alias AlertProcessor.Repo
  alias AlertProcessor.Model.{Alert, InformedEntity, Subscription, User}

  @doc """
  filter/1 takes a tuple including a subquery which represents the
  remaining subscriptions to be considered and
  an alert and returns the now remaining subscriptions to be considered
  in the form of an ecto queryable
  which have matched based on informed entities and
  an alert to pass through to the next filter. Otherwise the flow is
  shortcircuited if the user id list provided is missing or empty.
  """
  @spec filter({:ok, Ecto.Queryable.t, Alert.t}) :: {:ok, Ecto.Queryable.t, Alert.t}
  def filter({:ok, previous_query, %Alert{informed_entities: informed_entities} = alert}) do
    where_clause =
      Enum.reduce(informed_entities, false, fn(informed_entity, dynamic_query) ->
        informed_entity_where_clause = informed_entity_where_clause(informed_entity)
        dynamic(^informed_entity_where_clause or ^dynamic_query)
      end)

    normal_subscription_ids =
      Repo.all(from s in subquery(previous_query),
        join: ie in InformedEntity,
        on: ie.subscription_id == s.id,
        where: ^where_clause,
        select: s.id)

    admin_subscription_ids = admin_subscription_ids(previous_query, informed_entities)

    query =
      from s in Subscription,
        where: s.id in ^normal_subscription_ids,
        or_where: s.id in ^admin_subscription_ids

    {:ok, query, alert}
  end

  defp informed_entity_where_clause(informed_entity) do
    informed_entity
    |> Map.take(InformedEntity.queryable_fields)
    |> Enum.reduce(true, fn({k, v}, dynamic_query) ->
      if v do
        dynamic([s, ie], field(ie, ^k) == ^v and ^dynamic_query)
      else
        dynamic([s, ie], is_nil(field(ie, ^k)) and ^dynamic_query)
      end
    end)
  end

  defp admin_subscription_ids(previous_query, informed_entities) do
    subscription_types =
      informed_entities
      |> Enum.filter(&Map.has_key?(&1, :route_type))
      |> Enum.map(&Subscription.subscription_type_from_route_type(Map.get(&1, :route_type)))

    case subscription_types do
      [] ->
        []
      _ ->
        Repo.all(from s in subquery(previous_query),
          join: u in User,
          where: u.role == "application_administration",
          where: fragment("? not in (select ie.subscription_id from informed_entities ie)", s.id),
          where: s.type in ^subscription_types,
          select: s.id)
    end
  end
end
