defmodule AlertProcessor.Subscription.AmenitiesMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  amenities into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper, except: [map_timeframe: 1]
  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.Subscription

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
    Map.put(params, "alert_priority_type", "high")
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
    stop_ids = params["stops"]
    |> String.split(",", trim: true)
    |> station_ids_from_names()
    Map.put(params, "stops", stop_ids)
  end

  # TODO: this will be refactored to use ServiceInfoCache.get_stop_by_name/1 once #148 is merged
  defp station_ids_from_names(names) do
    with {:ok, subway_stations} <- ServiceInfoCache.get_subway_full_routes,
      {:ok, cr_stations} <- ServiceInfoCache.get_commuter_rail_info do
      subway_stations
      |> Kernel.++(cr_stations)
      |> Enum.map(& &1.stop_list)
      |> List.flatten
      |> Enum.reduce([], fn({name, id}, acc) ->
        if Enum.member?(names, name) && !Enum.member?(acc, id) do
          acc ++ [id]
        else
          acc
        end
      end)
    else
      _error -> :error
    end
  end

  defp map_entities(subscriptions, params) do
    with subscriptions <- map_amenities(subscriptions, params),
         [_sub | _t] <- subscriptions do
      {:ok, filter_duplicate_entities(subscriptions)}
    else
      _ -> :error
    end
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
