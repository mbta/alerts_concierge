defmodule ConciergeSite.SubscriptionView do
  @moduledoc """
  Subscription view which includes helper functions for displaying subscriptions
  """
  use ConciergeSite.Web, :view

  alias AlertProcessor.Helpers.DateTimeHelper
  alias AlertProcessor.Model.{InformedEntity, Subscription}

  @type subscription_info :: %{
    amenity: [Subscription.t],
    boat: [Subscription.t],
    bus: [Subscription.t],
    commuter_rail: [Subscription.t],
    subway: [Subscription.t]
  }

  @doc """
  sorted_subscriptions/1 takes a list of subscriptions and returns it in a grouped
  and sorted format to easily display all the subscriptions in a meaningful way
  to a user.
  """
  @spec sorted_subscriptions([Subscription.t]) :: subscription_info
  def sorted_subscriptions(subscriptions) do
    subscription_map =
      subscriptions
      |> Enum.sort_by(fn(subscription) ->
        route_key = subscription |> parse_route() |> String.split("-") |> List.first()
        origin_dest_key = [subscription.origin, subscription.destination] |> Enum.sort() |> Enum.join()
        {route_key, origin_dest_key, subscription.start_time}
      end)
      |> Enum.group_by(& &1.type)
    Map.merge(%{amenity: [], boat: [], bus: [], commuter_rail: [], subway: []}, subscription_map)
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
        [timeframe(subscription), " | ", direction_name(subscription), " ", parse_headsign(subscription)]
    end
  end

  defp timeframe(subscription) do
    [
      pretty_time(subscription.start_time),
      " - ",
      pretty_time(subscription.end_time),
      ", ",
      subscription.relevant_days |> Enum.map(&String.capitalize(Atom.to_string(&1))) |> Enum.intersperse(", ")
    ]
  end

  defp pretty_time(timestamp) do
    local_time = DateTimeHelper.utc_time_to_local(timestamp)
    {:ok, output} = Calendar.Strftime.strftime(local_time, "%l:%M%P")
    output
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
      [id] -> id
      _ -> :roaming
    end
  end

  defp parse_headsign(subscription) do
    case parse_direction(subscription) do
      nil ->
        ""
      direction ->
        {:ok, headsign} = AlertProcessor.ServiceInfoCache.get_headsign(:subway, subscription.origin, subscription.destination, direction)
        [" to ", headsign]
    end
  end
end
