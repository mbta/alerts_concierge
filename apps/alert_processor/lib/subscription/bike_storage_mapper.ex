defmodule AlertProcessor.Subscription.BikeStorageMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  bike_storage into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper, except: [map_timeframe: 1]
  alias AlertProcessor.Model.Subscription

  defdelegate build_subscription_transaction(subscriptions, user, originator),
    to: AlertProcessor.Subscription.Mapper

  @doc """
  map_subscription/1 receives a map of bike_storage subscription params and returns
  arrays of subscription_info to create in the database
  to be used for matching against alerts.
  """
  @spec map_subscriptions(map) :: {:ok, [Subscription.subscription_info()]} | :error
  def map_subscriptions(params) do
    params =
      params
      |> remove_empty_strings()
      |> map_stop_names()
      |> set_alert_priority()

    params
    |> map_timeframe
    |> map_priority(params)
    |> map_type(:bike_storage)
    |> map_entities(params)
  end

  defp set_alert_priority(params) do
    Map.put(params, "alert_priority_type", "low")
  end

  defp remove_empty_strings(params) do
    Enum.reduce(params, %{}, fn {k, v}, acc ->
      if is_list(v) do
        Map.put(acc, k, Enum.reject(v, &(&1 == "")))
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
    with subscriptions <- map_bike_storage(subscriptions, params),
         [_sub | _t] <- with_entities(subscriptions) do
      {:ok, filter_duplicate_entities(subscriptions)}
    else
      _ -> :error
    end
  end

  defp with_entities(subscriptions) do
    Enum.filter(subscriptions, fn {_, ie} ->
      length(ie) > 0
    end)
  end

  defp map_timeframe(%{"relevant_days" => relevant_days}) do
    [
      %Subscription{
        start_time: ~T[00:00:00],
        end_time: ~T[23:59:59],
        relevant_days: Enum.map(relevant_days, &String.to_existing_atom/1)
      }
    ]
  end
end
