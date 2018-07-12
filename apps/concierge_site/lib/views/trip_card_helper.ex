defmodule ConciergeSite.TripCardHelper do

  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML.Link, only: [link: 2]
  import Phoenix.Controller, only: [get_csrf_token: 0]
  import ConciergeSite.TimeHelper, only: [format_time_string: 2, time_to_string: 1]
  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.{Trip, Subscription}

  @station_features [elevator: "Elevators", escalator: "Escalators", bike_storage: "Bike storage", parking_area: "Parking"]

  @spec render(Plug.Conn.t, atom | Trip.t) :: Phoenix.HTML.safe
  def render(conn, %Trip{trip_type: :accessibility, id: id} = trip) do
    content_tag :div, class: "card trip__card btn btn-outline-primary", data: [trip_card: "link",
                                                                               link_type: "accessibility",
                                                                               trip_id: id] do
      accessibility_content(trip, conn, id)
    end
  end
  def render(conn, %Trip{id: id} = trip) do
    content_tag :div, class: "card trip__card btn btn-outline-primary", data: [trip_card: "link",
                                                                               link_type: "commute",
                                                                               trip_id: id] do
      commute_content(trip, conn, id)
    end
  end
  def render(_), do: ""

  @spec display(Plug.Conn.t, atom | Trip.t) :: Phoenix.HTML.safe
  def display(conn, %Trip{trip_type: :accessibility, id: id} = trip) do
    content_tag :div, class: "card trip__card trip__card--display btn btn-outline-primary" do
      accessibility_content(trip, conn, id)
    end
  end
  def display(conn, %Trip{id: id} = trip) do
    content_tag :div, class: "card trip__card trip__card--display btn btn-outline-primary" do
      commute_content(trip, conn, id)
    end
  end
  def display(_), do: ""

  @spec accessibility_content(Trip.t, Plug.Conn.t, String.t) :: [Phoenix.HTML.safe]
  defp accessibility_content(%Trip{trip_type: :accessibility, relevant_days: relevant_days,
                                  facility_types: facility_types, subscriptions: subscriptions}, conn, id) do
    [
      content_tag :div, class: "trip__card--top" do
        [
          delete_link(id),
          content_tag :span, class: "trip__card--route-icon" do
            ConciergeSite.IconViewHelper.icon(:t)
          end,
          content_tag :span, class: "trip__card--route" do
            "Station features"
          end,
          content_tag :div, class: "trip__card--type" do
            "#{stops_and_routes(subscriptions)}"
          end
        ]
      end,
      content_tag :div, class: "trip__card--bottom" do
        [
          edit_link(conn, :accessibility, id),
          content_tag :div, class: "trip__card--type" do
            "#{facility_types(facility_types)}"
          end,
          content_tag :div, class: "trip__card--type" do
            "#{days(relevant_days)}"
          end
        ]
      end
    ]
  end

  @spec commute_content(Trip.t, Plug.Conn.t, String.t) :: [Phoenix.HTML.safe]
  defp commute_content(%Trip{subscriptions: subscriptions, roundtrip: roundtrip, relevant_days: relevant_days,
  start_time: start_time, end_time: end_time, return_start_time: return_start_time,
  return_end_time: return_end_time, facility_types: facility_types}, conn, id) do
    [
      content_tag :div, class: "trip__card--top" do
        [
          delete_link(id),
          routes(subscriptions),
          content_tag :div, class: "trip__card--top-details" do
            [
              roundtrip(roundtrip),
              stops(subscriptions)
            ]
          end
        ]
      end,
      content_tag :div, class: "trip__card--bottom" do
        [
          edit_link(conn, :commute, id),
          content_tag :div, class: "trip__card--type" do
            "#{facility_types(facility_types)}"
          end,
          days(relevant_days),
          trip_times({start_time, end_time}, {return_start_time, return_end_time})
        ]
      end
    ]
  end

  @spec routes([Subscription.t]) :: [Phoenix.HTML.safe]
  defp routes(subscriptions) do
    subscriptions
    |> exclude_return_trip_subscriptions()
    |> collapse_duplicate_green_legs()
    |> Enum.map(fn (subscription) ->
      content_tag :div, class: "trip__card--route-container" do
        [
          content_tag :span, class: "trip__card--route-icon" do
            icon(subscription.type, subscription.route)
          end,
          content_tag :span, class: "trip__card--route" do
            route_name(subscription.route)
          end
        ]
      end
    end)
  end

  @spec stops([Subscription.t]) :: Phoenix.HTML.safe
  defp stops(subscriptions) do
    first_trip_subscriptions = subscriptions |>
      exclude_return_trip_subscriptions()
    origin = List.first(first_trip_subscriptions).origin
    destination = List.last(first_trip_subscriptions).destination

    content_tag :span, class: "trip__card--stops" do
      case {origin, destination} do
        {nil, nil} -> ""
        {nil, destination} -> ["to ", stop_name(destination)]
        {origin, nil} -> ["from ", stop_name(origin)]
        {origin, destination} -> ": #{stop_name(origin)} — #{stop_name(destination)}"
      end
    end
  end

  @spec collapse_duplicate_green_legs([Subscription.t]) :: [Subscription.t] 
  defp collapse_duplicate_green_legs(subscriptions) do
    Enum.reduce(subscriptions, [], fn(subscription, unique_subscriptions) ->
      case Enum.find_index(unique_subscriptions, fn(%{origin: origin, destination: destination}) ->
        subscription.route_type == 0 && origin == subscription.origin && destination == subscription.destination
      end) do
        nil -> unique_subscriptions ++ [subscription]
        index -> List.update_at(unique_subscriptions, index, fn(original_subscription) ->
          %{original_subscription | route: add_route_to_subscription(original_subscription.route, subscription.route) }
        end)
      end
    end)
  end

  @spec add_route_to_subscription([String.t] | String.t, String.t) :: [String.t] 
  defp add_route_to_subscription(original, additional) when is_list(original), do: original ++ [additional]
  defp add_route_to_subscription(original, additional), do: [original, additional]

  @spec icon(atom, String.t) :: Phoenix.HTML.safe
  defp icon(_, "Mattapan"), do: ConciergeSite.IconViewHelper.icon(:mattapan)
  defp icon(:subway, routes) when is_list(routes), do: Enum.map(routes, fn(route) -> icon(:subway, route) end)
  defp icon(:subway, route), do: ConciergeSite.IconViewHelper.icon(String.to_atom(String.downcase(route)))
  defp icon(:cr, _), do: ConciergeSite.IconViewHelper.icon(:commuter_rail)
  defp icon(:bus, _), do: ConciergeSite.IconViewHelper.icon(:bus)
  defp icon(:ferry, _), do: ConciergeSite.IconViewHelper.icon(:ferry)

  @spec roundtrip(boolean) :: String.t
  defp roundtrip(true), do: "Round-trip"
  defp roundtrip(false), do: "One-way"

  @spec days([atom]) :: String.t
  defp days([:monday, :tuesday, :wednesday, :thursday, :friday]), do: "Weekdays"
  defp days([:saturday, :sunday]), do: "Weekends"
  defp days([:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]), do: "Every day"
  defp days(days) do
    days
    |> Enum.map(& String.slice(String.capitalize(Atom.to_string(&1)), 0..2))
    |> Enum.join(", ")
  end

  @spec trip_times({Time.t, Time.t}, {Time.t, Time.t} | {nil, nil}) :: Phoenix.HTML.safe
  defp trip_times(start_time, {nil, nil}) do
    content_tag :div, class: "trip__card--times" do
      format_time(start_time)
    end
  end
  defp trip_times(start_time, end_time) do
    content_tag :div, class: "trip__card--times" do
      "#{format_time(start_time)}, #{format_time(end_time)}"
    end
  end

  @spec format_time({Time.t, Time.t}) :: String.t
  defp format_time({start_time, end_time}) do
    "#{String.slice(format_time_string(time_to_string(start_time), "%l:%M%p"), 0..-2)} - #{String.slice(format_time_string(time_to_string(end_time), "%l:%M%p"), 0..-2)}"
  end

  @spec facility_types([atom] | nil) :: String.t
  defp facility_types(nil), do: ""
  defp facility_types(facility_types) do
    facility_types
    |> Enum.map(& @station_features[&1])
    |> Enum.intersperse(", ")
  end

  @spec stops_and_routes([Subscription.t]) :: [String.t]
  defp stops_and_routes(subscriptions) do
    subscriptions
    |> Enum.map(fn(subscription) ->
      case {subscription.origin, subscription.route} do
        {stop_id, nil} -> stop_name(stop_id)
        {nil, route_id} -> route_name(route_id)
      end
    end)
    |> Enum.intersperse(", ")
  end

  @spec stop_name(String.t) :: String.t
  defp stop_name(stop_id) do
    {:ok, {name, _, _, _}} = ServiceInfoCache.get_stop(stop_id)
    name
  end

  @spec route_name(String.t) :: String.t
  defp route_name(routes) when is_list(routes), do: "Green Line"
  defp route_name("Green"), do: "Green Line"
  defp route_name("Green-B"), do: "Green Line B"
  defp route_name("Green-C"), do: "Green Line C"
  defp route_name("Green-D"), do: "Green Line D"
  defp route_name("Green-E"), do: "Green Line E"
  defp route_name(route_id) do
    {:ok, route} = ServiceInfoCache.get_route(route_id)
    case route.long_name do
      "" -> route.short_name
      _ -> route.long_name
    end
  end

  @spec edit_link(Plug.Conn.t, atom, String.t) :: Phoenix.HTML.safe
  defp edit_link(conn, :commute, id) do
    link("Edit", to: ConciergeSite.Router.Helpers.v2_trip_path(conn, :edit, id), class: "trip__card--edit-link")
  end
  defp edit_link(conn, :accessibility, id) do
    link("Edit", to: ConciergeSite.Router.Helpers.v2_accessibility_trip_path(conn, :edit, id), class: "trip__card--edit-link")
  end

  @spec delete_link(String.t) :: Phoenix.HTML.safe
  defp delete_link(trip_id) do
    content_tag :a, class: "trip__card--delete-link", tabindex: "0", data: [toggle: "modal",
                                                                            target: "#deleteModal",
                                                                            trip_id: trip_id,
                                                                            token: get_csrf_token()] do
      "Delete"
    end
  end

  defp exclude_return_trip_subscriptions(subscriptions) do
    subscriptions
    |> Enum.reject(& &1.return_trip)
  end
end
