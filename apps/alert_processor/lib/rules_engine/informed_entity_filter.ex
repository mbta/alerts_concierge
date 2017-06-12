defmodule AlertProcessor.InformedEntityFilter do
  @moduledoc """
  Filter users based on informed entity records tied to subscriptions.
  """

  import Ecto.Query
  alias AlertProcessor.Model.{Alert, InformedEntity}

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
      Enum.reduce(informed_entities, false, fn(informed_entity), dynamic_query ->
        informed_entity_where_clause = informed_entity_where_clause(informed_entity)
        dynamic(^informed_entity_where_clause or ^dynamic_query)
      end)

    query = from s in subquery(previous_query),
      join: ie in InformedEntity,
      on: ie.subscription_id == s.id,
      where: ^where_clause

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
end
