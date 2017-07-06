defmodule AlertProcessor.Subscription.AmenitiesMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  amenities into the relevant subscription and informed entity structs.
  """

  import AlertProcessor.Subscription.Mapper, except: [map_timeframe: 1]
  alias AlertProcessor.Model.Subscription

  @doc """
  map_subscription/1 receives a map of amenity subscription params and returns
  arrays of subscription_info to create in the database
  to be used for matching against alerts.
  """
  @spec map_subscriptions(map) :: {:ok, [Subscription.subscription_info]} | :error
  def map_subscriptions(subscription_params) do
    subscriptions =
      subscription_params
      |> map_timeframe()
      |> map_priority(subscription_params)
      |> map_type(:amenity)

    {:ok, map_entities(subscriptions, subscription_params)}
  end

  defp map_entities(subscriptions, params) do
    subscriptions
    |> map_amenities(params)
    |> filter_duplicate_entities()
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
