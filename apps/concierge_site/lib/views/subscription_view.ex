defmodule ConciergeSite.SubscriptionView do
  @moduledoc """
  Subscription view which includes helper functions for displaying subscriptions
  """
  use ConciergeSite.Web, :view

  alias AlertProcessor.{Helpers, Model, ServiceInfoCache}
  alias Helpers.DateTimeHelper
  alias Model.{InformedEntity, Subscription}
  alias Calendar.Strftime
  alias ConciergeSite.{AmenitySubscriptionView, SubscriptionHelper}

  import SubscriptionHelper,
    only: [direction_id: 1, relevant_days: 1]
  import AmenitySubscriptionView,
    only: [amenity_facility_type: 1, amenity_schedule: 1]

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
        route = parse_route(subscription) || %{order: 1}
        relevant_days_key =
          {
            !Enum.member?(subscription.relevant_days, :weekday),
            !Enum.member?(subscription.relevant_days, :saturday),
            !Enum.member?(subscription.relevant_days, :sunday)
          }
        {route.order, relevant_days_key, subscription.start_time}
      end)
      |> Enum.group_by(& &1.type)
    Map.merge(%{amenity: [], boat: [], bus: [], commuter_rail: [], subway: []}, subscription_map)
  end

  def subscription_info(%{type: :amenity} = subscription) do
    content_tag :div, class: "subscription-info" do
      [
        content_tag :div, class: "subscription-route" do
          "Station Amenities"
        end,
        content_tag :div, class: "subscription-details" do
          route_body(subscription, nil)
        end
      ]
    end
  end

  def subscription_info(subscription, additional_info \\ nil) do
    content_tag :div, class: "subscription-info" do
      [
        content_tag :div, class: "subscription-route" do
          route_header(subscription)
        end,
        content_tag :div, class: "subscription-details" do
          route_body(subscription, additional_info)
        end
      ]
    end
  end

  defp route_header(%{type: :bus} = subscription) do
    [
      content_tag(:span, parse_route(subscription).long_name),
      content_tag(:i, "", class: "fa fa-long-arrow-right"),
      content_tag(:span, direction_name(subscription))
    ]
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

  defp route_body(%{type: :amenity} = subscription, _) do
    [
      content_tag :div, class: "subscription-facility-types" do
        amenity_facility_type(subscription)
      end,
      content_tag :div, class: "subscription-amenity-schedule" do
        amenity_schedule(subscription)
      end
    ]
  end
  defp route_body(%{type: :subway} = subscription, _) do
    case direction_name(subscription) do
      :roaming ->
        timeframe(subscription)
      _ ->
        [timeframe(subscription), " | ", direction_name(subscription), " ", parse_headsign(subscription)]
    end
  end
  defp route_body(%{type: :commuter_rail, relevant_days: [relevant_days]} = subscription, commuter_rail_departure_time_map) do
    trip_entities =
      subscription.informed_entities
      |> Enum.filter(& InformedEntity.entity_type(&1) == :trip)
      |> Enum.sort_by(& commuter_rail_departure_time_map[&1.trip])

    for trip_entity <- trip_entities do
      content_tag(:p, [
        "Train ",
        trip_entity.trip,
        ", ",
        relevant_days |> to_string() |> String.capitalize(),
        "s | Departs ",
        subscription.origin,
        " at ",
        commuter_rail_departure_time_map[trip_entity.trip]
      ])
    end
  end
  defp route_body(%{type: :bus} = subscription, _) do
    [timeframe(subscription), " | ", parse_headsign(subscription)]
  end

  defp timeframe(subscription) do
    [
      pretty_time(subscription.start_time),
      " - ",
      pretty_time(subscription.end_time),
      ", ",
      relevant_days(subscription)
    ]
  end

  defp pretty_time(timestamp) do
    local_time = DateTimeHelper.utc_time_to_local(timestamp)
    {:ok, output} = Strftime.strftime(local_time, "%l:%M%P")
    output
  end

  defp parse_route_id(subscription) do
    %InformedEntity{route: route} = Enum.find(subscription.informed_entities, fn(%InformedEntity{route: route}) -> !is_nil(route) end)
    route
  end

  defp parse_route(subscription) do
    {:ok, route} = subscription |> parse_route_id() |> ServiceInfoCache.get_route()
    route
  end

  defp direction_name(subscription) do
    case parse_direction(subscription) do
      :roaming ->
        :roaming
      direction ->
        {:ok, direction_name} = ServiceInfoCache.get_direction_name(parse_route_id(subscription), direction)
        direction_name
    end
  end

  defp parse_direction(subscription) do
    subscription.informed_entities
    |> Enum.filter(&(!is_nil(&1.direction_id)))
    |> Enum.map(&(&1.direction_id))
    |> Enum.uniq()
    |> case do
      [id] -> id
      _ -> :roaming
    end
  end

  defp parse_headsign(%{type: :subway} = subscription) do
    case parse_direction(subscription) do
      nil ->
        ""
      direction ->
        {:ok, headsign} = ServiceInfoCache.get_headsign(subscription.origin, subscription.destination, direction)
        [" to ", headsign]
    end
  end
  defp parse_headsign(%{type: :bus} = subscription) do
    headsigns = parse_route(subscription).headsigns
    headsign = Map.get(headsigns, direction_id(subscription))
    if length(headsign) > 1 do
      Enum.join(headsign, " via ")
    else
      headsign
    end
  end
end
