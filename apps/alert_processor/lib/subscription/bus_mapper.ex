defmodule AlertProcessor.Subscription.BusMapper do
  @moduledoc """
  Module to convert a set of subscription creation parameters for
  bus into the relevant subscription and informed entity structs.
  """


  alias AlertProcessor.Helpers.DateTimeHelper
  alias AlertProcessor.Model.{InformedEntity, Subscription}

  @doc """
  map_subscription/1 receives a map of bus subscription params and returns
  arrays of subscription(s) and informed entities to creat in the database
  to be used for matching against alerts.
  """
  @spec map_subscription(map) :: {:ok, [Subscription.t], [InformedEntity.t]} | :error
  def map_subscription(subscription_params) do
    with {:ok, subscriptions} <- map_timeframe(subscription_params),
         {:ok, subscriptions} <- map_priority(subscriptions, subscription_params),
         {:ok, subscriptions, informed_entities} <- map_entities(subscriptions, subscription_params) do
      {:ok, subscriptions, informed_entities}
    else
      _ -> :error
    end
  end

  defp map_timeframe(%{"departure_start" => ds, "departure_end" => de, "return_start" => nil, "return_end" => nil, "relevant_days" => rd}) do
    subscription = %Subscription{start_time: DateTimeHelper.timestamp_to_utc(ds), end_time: DateTimeHelper.timestamp_to_utc(de), relevant_days: Enum.map(rd, &String.to_existing_atom/1)}

    {:ok, [subscription]}
  end

  defp map_timeframe(%{"departure_start" => ds, "departure_end" => de, "return_start" => rs, "return_end" => re, "relevant_days" => rd}) do
    sub1 =
      %Subscription{
        start_time: DateTimeHelper.timestamp_to_utc(ds),
        end_time: DateTimeHelper.timestamp_to_utc(de),
        relevant_days: Enum.map(rd, &String.to_existing_atom/1)
      }
    sub2 =
      %Subscription{
        start_time: DateTimeHelper.timestamp_to_utc(rs),
        end_time: DateTimeHelper.timestamp_to_utc(re),
        relevant_days: Enum.map(rd, &String.to_existing_atom/1)
      }

    {:ok, [sub1, sub2]}
  end

  defp map_priority(subscriptions, %{"alert_priority_type" => alert_priority_type}) when is_list(subscriptions) do
    {:ok, Enum.map(subscriptions, fn(subscription) ->
      %{subscription | alert_priority_type: String.to_existing_atom(alert_priority_type)}
    end)}
  end

  defp map_entities(subscriptions, params) do
    with %{"route" => route} <- params,
         {subscriptions, informed_entities} <- map_route_type(subscriptions),
         {subscriptions, informed_entities} <- map_routes(subscriptions, informed_entities, route) do
      {:ok, subscriptions, informed_entities}
    else
      _ -> :error
    end
  end

  defp map_route_type(subscriptions) do
    {subscriptions, [%InformedEntity{route_type: 3}]}
  end

  defp map_routes(subscriptions, informed_entities, route) do
    route_entities =
      [
        %InformedEntity{route: route, route_type: 3},
        %InformedEntity{route: route, route_type: 3, direction_id: 0},
        %InformedEntity{route: route, route_type: 3, direction_id: 1}
      ]

    {subscriptions, informed_entities ++ route_entities}
  end
end
