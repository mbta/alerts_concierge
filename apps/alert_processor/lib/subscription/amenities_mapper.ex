defmodule AlertProcessor.Subscription.AmenitiesMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  amenities into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper, except: [map_timeframe: 1]
  import Ecto.Query
  alias Ecto.Multi
  alias AlertProcessor.Repo
  alias AlertProcessor.Model.{InformedEntity, Subscription, User}

  defdelegate build_subscription_transaction(subscriptions, user, originator), to: AlertProcessor.Subscription.Mapper

  @doc """
  build_subscription_update_transaction/3 receives a the current subscription
  and the update params and builds and Ecto.Multi transaction.

  1. It updates the subscription data
  2. It regenerates the informed entities for that subscription from the new data
  """
  def build_subscription_update_transaction(subscription, subscription_infos, originator) do
    origin =
      if subscription.user_id != User.wrap_id(originator).id do
        "admin:update-subscription"
      end
    [{sub_changes, informed_entities}] = subscription_infos
    params =
      sub_changes
      |> Map.put(:informed_entities, informed_entities)
      |> Map.from_struct()

    current_informed_entity_ids =
      subscription.informed_entities
      |> Enum.map(& &1.id)

    query = from(ie in InformedEntity, where: ie.id in ^current_informed_entity_ids)
    current_informed_entities = Repo.all(query)

    multi = informed_entities
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn({ie, index}, acc) ->
        ie_to_insert = Map.put(ie, :subscription_id, subscription.id)
        Multi.run(acc, {:new_informed_entity, index}, fn _ ->
          PaperTrail.insert(ie_to_insert, originator: User.wrap_id(originator), meta: %{owner: subscription.user_id})
        end)
      end)

    current_informed_entities
    |> Enum.with_index
    |> Enum.reduce(multi, fn({ie, index}, acc) ->
      Multi.run(acc, {:remove_current, index}, fn _ ->
        PaperTrail.delete(ie, originator: User.wrap_id(originator), meta: %{owner: subscription.user_id})
      end)
    end)
    |> Multi.run({:subscription}, fn _ ->
      changeset = Subscription.update_changeset(subscription, params)
      PaperTrail.update(changeset, originator: User.wrap_id(originator), meta: %{owner: subscription.user_id}, origin: origin)
    end)
  end

  @doc """
  map_subscription/1 receives a map of amenity subscription params and returns
  arrays of subscription_info to create in the database
  to be used for matching against alerts.
  """
  @spec map_subscriptions(map) :: {:ok, [Subscription.subscription_info]} | :error
  def map_subscriptions(subscription_params) do
    params =
      subscription_params
      |> remove_empty_strings()
      |> map_stop_names()
      |> set_alert_priority()

    with {:ok, subscriptions} <- map_timeframe(params),
         {:ok, subscriptions} <- map_priority(subscriptions, params),
         subscriptions <- map_type(subscriptions, :amenity)
         do
      map_entities(subscriptions, params)
    else
      _ -> :error
    end
  end

  defp set_alert_priority(params) do
    Map.put(params, "alert_priority_type", "low")
  end

  defp remove_empty_strings(params) do
    Enum.reduce(params, %{}, fn({k, v}, acc) ->
      if is_list(v) do
        Map.put(acc, k, Enum.reject(v, & &1 == ""))
      else
        Map.put(acc, k, v)
      end
    end)
  end

  defp map_stop_names(params) do
    stop_ids = Map.get(params, "stops", [])
    Map.put(params, "stops", stop_ids)
  end

  defp map_entities(subscriptions, params) do
    with subscriptions <- map_amenities(subscriptions, params),
         [_sub | _t] <- with_entities(subscriptions) do
      {:ok, filter_duplicate_entities(subscriptions)}
    else
      _ -> :error
    end
  end

  defp with_entities(subscriptions) do
    Enum.filter(subscriptions, fn({_, ie}) ->
      length(ie) > 0
    end)
  end

  defp map_timeframe(%{"relevant_days" => relevant_days}) do
    {:ok, [
      %Subscription{
        start_time: ~T[00:00:00],
        end_time: ~T[23:59:59],
        relevant_days: Enum.map(relevant_days, &String.to_existing_atom/1)
      }
    ]}
  end
end
