defmodule ConciergeSite.SubscriptionView do
  use ConciergeSite.Web, :view

  alias AlertProcessor.Helpers.DateTimeHelper
  alias AlertProcessor.Model.InformedEntity

  def sorted_subscriptions(subscriptions) do
    with grouped_subscriptions <- group_subscriptions_by_mode_route_and_stations(subscriptions),
         sorted_by_earliest_time <- order_subscriptions_for_stations_by_earliest_time(grouped_subscriptions),
         subscription_map <- flatten_arrays(sorted_by_earliest_time) do
           Map.merge(%{amenity: [], boat: [], bus: [], commuter_rail: [], subway: []}, subscription_map)
    end
  end

  defp group_subscriptions_by_mode_route_and_stations(subscriptions) do
    Enum.reduce(subscriptions, %{}, fn(subscription, acc) ->
      route_key = subscription |> parse_route() |> String.split("-") |> List.first()
      origin_dest_key = Enum.sort([subscription.origin, subscription.destination]) |> Enum.join()
      update = %{{subscription.type, route_key, origin_dest_key} => [subscription]}

      Map.merge(acc, update, fn(_, s1, s2) ->
        Enum.sort_by(s1 ++ s2, &(&1.start_time))
      end)
    end)
  end

  defp order_subscriptions_for_stations_by_earliest_time(grouped_subscriptions) do
    Enum.reduce(grouped_subscriptions, %{}, fn({{type, line, _dest_origin}, subscriptions}, acc) ->
      update = %{{type, line} => [subscriptions]}

      Map.merge(acc, update, fn(_, curr_subs, new_subs) ->
        Enum.sort_by(curr_subs ++ new_subs, fn(subscriptions) ->
          [earliest_subscription | _] = subscriptions
          earliest_subscription.start_time
        end)
      end)
    end)
  end

  defp flatten_arrays(sorted_by_earliest_time) do
    Enum.reduce(sorted_by_earliest_time, %{}, fn({{type, _line}, subscriptions}, acc) ->
      flattened_subscriptions = Enum.flat_map(subscriptions, &(&1))

      Map.update(acc, type, flattened_subscriptions, fn(subs) ->
        subs ++ flattened_subscriptions
      end)
    end)
  end

  def subway_subscription_info(subscription) do
    content_tag :div, class: "subscription-info" do
      [
        content_tag :div, class: "subscription-route" do
          route_header(subscription)
        end,
        content_tag :div, class: "subscription-details" do
          route_body(subscription)
        end
      ]
    end
  end

  defp route_header(subscription) do
    case direction_name(subscription) do
      :roaming -> content_tag(:span, "#{subscription.origin} - #{subscription.destination}")
      _ -> [
            content_tag(:span, subscription.origin),
            content_tag(:i, "", class: "fa fa-long-arrow-right"),
            content_tag(:span, subscription.destination)
          ]
    end
  end

  defp route_body(subscription) do
    case direction_name(subscription) do
      :roaming ->
        timeframe(subscription)
      _ ->
        "#{timeframe(subscription)} | #{direction_name(subscription)} #{parse_headsign(subscription)}"
    end
  end

  defp timeframe(subscription) do
    "#{pretty_time(subscription.start_time)} - #{pretty_time(subscription.end_time)}, \
    #{Enum.map_join(subscription.relevant_days, ", ", & &1 |> Atom.to_string() |> String.capitalize())}"
  end

  defp pretty_time(timestamp) do
    with local_time <- DateTimeHelper.utc_time_to_local(timestamp),
      {:ok, output} <- Calendar.Strftime.strftime(local_time, "%l:%M%P") do
      output
    end
  end

  defp parse_route(subscription) do
    %InformedEntity{route: route} = Enum.find(subscription.informed_entities, fn(%InformedEntity{route: route}) -> !is_nil(route) end)
    route
  end

  defp direction_name(subscription) do
    case parse_direction(subscription) do
      :roaming ->
        :roaming
      direction ->
        {:ok, direction_name} = AlertProcessor.ServiceInfoCache.get_direction_name(:subway, parse_route(subscription), direction)
        direction_name
    end
  end

  defp parse_direction(subscription) do
    subscription.informed_entities
    |> Enum.filter_map(&(!is_nil(&1.direction_id)), &(&1.direction_id))
    |> Enum.uniq()
    |> case do
      [id | []] -> id
      _ -> :roaming
    end
  end

  defp parse_headsign(subscription) do
    direction = parse_direction(subscription)
    case direction do
      nil ->
        ""
      direction ->
        {:ok, headsign} = AlertProcessor.ServiceInfoCache.get_headsign(:subway, subscription.origin, subscription.destination, direction)
        " to " <> headsign
    end
  end
end
