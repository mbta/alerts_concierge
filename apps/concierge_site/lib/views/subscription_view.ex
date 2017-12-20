defmodule ConciergeSite.SubscriptionView do
  @moduledoc """
  Subscription view which includes helper functions for displaying subscriptions
  """
  use ConciergeSite.Web, :view

  alias AlertProcessor.{Model, ServiceInfoCache}
  alias Model.{InformedEntity, Route, Subscription}
  alias ConciergeSite.{AccessibilitySubscriptionView, ParkingSubscriptionView, BikeStorageSubscriptionView,
    BusSubscriptionView, SubscriptionHelper, TimeHelper}
  alias ConciergeSite.Router.Helpers

  import SubscriptionHelper,
    only: [direction_id: 1, relevant_days: 1]
  import AccessibilitySubscriptionView,
    only: [accessibility_facility_type: 1, accessibility_schedule: 1]
  import ParkingSubscriptionView,
    only: [parking_schedule: 1]
  import BikeStorageSubscriptionView,
    only: [bike_storage_schedule: 1]

  @type subscription_info :: %{
    ferry: [Subscription.t],
    bus: [Subscription.t],
    commuter_rail: [Subscription.t],
    subway: [Subscription.t],
    accessibility: [Subscription.t],
    parking: [Subscription.t],
    bike_storage: [Subscription.t]
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
        route = parse_route(subscription)
        relevant_days_key =
          {
            !Enum.member?(subscription.relevant_days, :weekday),
            !Enum.member?(subscription.relevant_days, :saturday),
            !Enum.member?(subscription.relevant_days, :sunday)
          }

        start_time_value = TimeHelper.normalized_time_value(subscription.start_time)
        {route.order, relevant_days_key, start_time_value}
      end)
      |> Enum.group_by(& &1.type)
    Map.merge(%{accessibility: [], parking: [], bike_storage: [], ferry: [], bus: [], commuter_rail: [], subway: []}, subscription_map)
  end

  def subscription_info(subscription, station_display_names \\ nil, departure_time_map \\ nil)
  def subscription_info(%{type: type} = subscription, station_display_names, departure_time_map) do
    if Enum.member?([:accessibility, :parking, :bike_storage, :bus, :commuter_rail, :ferry, :subway], type) do
      do_subscription_info(subscription, station_display_names, departure_time_map)
    else
      ""
    end
  end

  defp do_subscription_info(%{type: :accessibility} = subscription, _, _) do
    content_tag :div, class: "subscription-info" do
      [
        content_tag :div, class: "subscription-route" do
          "Accessibility Features"
        end,
        content_tag :div, class: "subscription-details" do
          route_body(subscription, nil, nil)
        end
      ]
    end
  end
  defp do_subscription_info(%{type: :parking} = subscription, _, _) do
    content_tag :div, class: "subscription-info" do
      [
        content_tag :div, class: "subscription-route" do
          "Parking"
        end,
        content_tag :div, class: "subscription-details" do
          route_body(subscription, nil, nil)
        end
      ]
    end
  end
  defp do_subscription_info(%{type: :bike_storage} = subscription, _, _) do
    content_tag :div, class: "subscription-info" do
      [
        content_tag :div, class: "subscription-route" do
          "Bike Storage"
        end,
        content_tag :div, class: "subscription-details" do
          route_body(subscription, nil, nil)
        end
      ]
    end
  end
  defp do_subscription_info(subscription, station_display_names, departure_time_map) when departure_time_map == %{} do
    content_tag :div, class: "subscription-info" do
      [
        content_tag :div, class: "subscription-route" do
          route_header(subscription, station_display_names)
        end,
        content_tag :div, class: "subscription-details" do
          [
            relevant_days(subscription),
            " from ",
            TimeHelper.format_time(subscription.start_time),
            " to ",
            TimeHelper.format_time(subscription.end_time)
          ]
        end
      ]
    end
  end
  defp do_subscription_info(subscription, station_display_names, departure_time_map) do
    content_tag :div, class: "subscription-info" do
      [
        content_tag :div, class: "subscription-route" do
          route_header(subscription, station_display_names)
        end,
        content_tag :div, class: "subscription-details" do
          route_body(subscription, station_display_names, departure_time_map)
        end
      ]
    end
  end

  def route_header(%{type: :accessibility}), do: "Accessibility"
  def route_header(%{type: :parking}), do: "Parking"
  def route_header(%{type: :bike_storage}), do: "Bike Storage"
  def route_header(%{type: :bus} = subscription, _) do
    route_entity_count = Subscription.route_count(subscription)
    if route_entity_count > 1 do
      [to_string(route_entity_count), " Bus Routes"]
    else
      [
        content_tag(:span, Route.name(parse_route(subscription))),
        content_tag(:i, "", class: "fa fa-long-arrow-right"),
        content_tag(:span, direction_name(subscription))
      ]
    end
  end
  def route_header(subscription, station_display_names) do
    case direction_name(subscription) do
      :roaming -> content_tag(:span, "#{Map.get(station_display_names, subscription.origin, subscription.origin)} - #{Map.get(station_display_names, subscription.destination, subscription.destination)}")
      _ -> [
            content_tag(:span, Map.get(station_display_names, subscription.origin, subscription.origin)),
            content_tag(:i, "", class: "fa fa-long-arrow-right"),
            content_tag(:span, Map.get(station_display_names, subscription.destination, subscription.destination))
          ]
    end
  end

  defp route_body(%{type: :accessibility} = subscription, _, _) do
    [
      content_tag :div, class: "subscription-facility-types" do
        accessibility_facility_type(subscription)
      end,
      content_tag :div, class: "subscription-amenity-schedule" do
        accessibility_schedule(subscription)
      end
    ]
  end
  defp route_body(%{type: :parking} = subscription, _, _) do
    [
      content_tag :div, class: "subscription-amenity-schedule" do
        parking_schedule(subscription)
      end
    ]
  end
  defp route_body(%{type: :bike_storage} = subscription, _, _) do
    [
      content_tag :div, class: "subscription-amenity-schedule" do
        bike_storage_schedule(subscription)
      end
    ]
  end
  defp route_body(%{type: :subway} = subscription, _, _) do
    case direction_name(subscription) do
      :roaming ->
        timeframe(subscription)
      _ ->
        [timeframe(subscription), " | ", direction_name(subscription), " ", parse_headsign(subscription)]
    end
  end
  defp route_body(%{type: :bus} = subscription,  _, _) do
    route_entity_count = Subscription.route_count(subscription)
    if route_entity_count > 1 do
      [
        BusSubscriptionView.multi_route_subscription_details(subscription),
        timeframe(subscription)
      ]
    else
      [timeframe(subscription), " | ", parse_headsign(subscription)]
    end
  end
  defp route_body(%{type: :commuter_rail, relevant_days: [relevant_days]} = subscription, station_display_names, departure_time_map) do
    for trip_entity <- get_trip_entities(subscription, departure_time_map) do
      departure_time_iodata = departure_time_iodata(departure_time_map[trip_entity.trip], fn time -> [" at ", time] end)

      content_tag(:p, [
        "Train ",
        trip_entity.trip,
        ", ",
        relevant_days |> to_string() |> String.capitalize(),
        "s | Departs ",
        Map.get(station_display_names, subscription.origin, subscription.origin),
        departure_time_iodata
      ])
    end
  end
  defp route_body(%{type: :ferry, relevant_days: [relevant_days]} = subscription, station_display_names, departure_time_map) do
    for trip_entity <- get_trip_entities(subscription, departure_time_map) do
      departure_time_iodata = departure_time_iodata(departure_time_map[trip_entity.trip], fn time -> [time, ", "] end)

      content_tag(:p, [
        departure_time_iodata,
        relevant_days |> to_string() |> String.capitalize(),
        "s | Departs from ",
        Map.get(station_display_names, subscription.origin, subscription.origin)
      ])
    end
  end

  defp departure_time_iodata(nil, _), do: ""
  defp departure_time_iodata(time, iodata_fn) do
    formatted_time = time |> Calendar.Strftime.strftime!("%l:%M%P") |> String.trim()
    iodata_fn.(formatted_time)
  end

  defp get_trip_entities(subscription, departure_time_map) do
    subscription.informed_entities
    |> Enum.filter(& InformedEntity.entity_type(&1) == :trip)
    |> Enum.sort_by(& TimeHelper.normalized_time_value(departure_time_map[&1.trip]))
  end

  defp timeframe(subscription) do
    [
      TimeHelper.format_time(subscription.start_time),
      " - ",
      TimeHelper.format_time(subscription.end_time),
      ", ",
      relevant_days(subscription)
    ]
  end

  defp parse_route_id(subscription) do
    case Enum.find(subscription.informed_entities, fn(%InformedEntity{route: route}) -> !is_nil(route) end) do
      %InformedEntity{route: route} -> route
      nil -> nil
    end
  end

  def parse_route(%Subscription{type: :accessibility}), do: %{order: 1}
  def parse_route(%Subscription{type: :parking}), do: %{order: 1}
  def parse_route(%Subscription{type: :bike_storage}), do: %{order: 1}
  def parse_route(subscription) do
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

  def vacation_color_class(vacation_start, vacation_end) do
    if on_vacation?(vacation_start, vacation_end) do
      "callout-active"
    else
      "callout-inactive"
    end
  end

  def vacation_banner_content(_, %DateTime{year: 9999}),
    do: "Your alerts have been paused."

  def vacation_banner_content(vacation_start, vacation_end) do
    if on_vacation?(vacation_start, vacation_end) do
      [
        "Your alerts have been paused until ",
        Calendar.Strftime.strftime!(vacation_end, "%B %e, %Y.")
      ]
    else
      "Don't need updates right now?"
    end
  end

  def on_vacation?(nil, _), do: false
  def on_vacation?(_, nil), do: false
  def on_vacation?(vacation_start, vacation_end) do
    with now <- NaiveDateTime.utc_now(),
      :lt <- NaiveDateTime.compare(vacation_start, now),
      :lt <- NaiveDateTime.compare(now, vacation_end) do
      true
    else
     _ -> false
    end
  end

  def subscription_edit_path(conn, %Subscription{type: :bus} = subscription) do
    Helpers.bus_subscription_path(conn, :edit, subscription)
  end
  def subscription_edit_path(conn, %Subscription{type: :subway} = subscription) do
    Helpers.subway_subscription_path(conn, :edit, subscription)
  end
  def subscription_edit_path(conn, %Subscription{type: :commuter_rail} = subscription) do
    Helpers.commuter_rail_subscription_path(conn, :edit, subscription)
  end
  def subscription_edit_path(conn, %Subscription{type: :boat} = subscription) do
    Helpers.ferry_subscription_path(conn, :edit, subscription)
  end
  def subscription_edit_path(conn, %Subscription{type: :accessibility} = subscription) do
    Helpers.accessibility_subscription_path(conn, :edit, subscription)
  end
  def subscription_edit_path(conn, %Subscription{type: :parking} = subscription) do
    Helpers.parking_subscription_path(conn, :edit, subscription)
  end
  def subscription_edit_path(conn, %Subscription{type: :bike_storage} = subscription) do
    Helpers.bike_storage_subscription_path(conn, :edit, subscription)
  end
end
