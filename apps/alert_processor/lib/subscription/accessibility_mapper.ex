defmodule AlertProcessor.Subscription.AccessibilityMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  accessibility into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper, except: [map_timeframe: 1]
  alias AlertProcessor.Model.Subscription

  defdelegate build_subscription_transaction(subscriptions, user, originator), to: AlertProcessor.Subscription.Mapper

  @doc """
  map_subscription/1 receives a map of accessibility subscription params and returns
  arrays of subscription_info to create in the database
  to be used for matching against alerts.
  """
  @spec map_subscriptions(map) :: {:ok, [Subscription.subscription_info]} | :error
  def map_subscriptions(params) do
    params = params
    |> remove_empty_strings()
    |> map_stop_names()
    |> set_alert_priority()

    params
    |> map_timeframe
    |> map_priority(params)
    |> map_type(:accessibility)
    |> map_entities(params)
  end

  def subscription_to_informed_entities(%Subscription{route: route_id} = sub) do
    params = %{
      "origin" => sub.origin,
      "destination" => sub.destination,
      "direction" => sub.direction_id,
      "route" => route_id, 
      "relevant_days" => sub.relevant_days,
      "alert_priority_type" => sub.alert_priority_type,
      "trips" => [],
    }
    |> map_stop_names()
    |> set_alert_priority()
    |> map_timeframe

    [sub]
    |> map_priority(params)
    |> map_type(:accessibility)
    |> map_entities(params)
    |> case do
      [{_subscription, informed_entities}] ->
        informed_entities
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
    with subscriptions <- map_accessibility(subscriptions, params),
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
    [%Subscription{
      start_time: ~T[00:00:00],
      end_time: ~T[23:59:59],
      relevant_days: Enum.map(relevant_days, &String.to_existing_atom/1)
    }]
  end
end
