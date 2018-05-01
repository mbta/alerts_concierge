defmodule ConciergeSite.TripCardHelper do

  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML.Link, only: [link: 2]
  import ConciergeSite.TimeHelper, only: [format_time_string: 2, time_to_string: 1]
  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.{Trip, Subscription}

  @spec render(Plug.Conn.t, atom | Trip.t) :: Phoenix.HTML.safe
  def render(conn, %Trip{trip_type: :accessibility, id: id} = trip) do
    link to: ConciergeSite.Router.Helpers.v2_accessibility_trip_path(conn, :edit, id), class: "card trip__card btn btn-outline-primary" do
      accessibility_content(trip)
    end
  end
  def render(conn, %Trip{id: id} = trip) do
    link to: ConciergeSite.Router.Helpers.v2_trip_path(conn, :edit, id), class: "card trip__card btn btn-outline-primary" do
      commute_content(trip)
    end
  end
  def render(_), do: ""

  def display(_conn, %Trip{trip_type: :accessibility} = trip) do
    content_tag :div, class: "card trip__card trip__card--display btn btn-outline-primary" do
      accessibility_content(trip)
    end
  end
  def display(_conn, trip) do
    content_tag :div, class: "card trip__card trip__card--display btn btn-outline-primary" do
      commute_content(trip)
    end
  end
  def display(_), do: ""

  @spec accessibility_content(Trip.t) :: [Phoenix.HTML.safe]
  defp accessibility_content(%Trip{trip_type: :accessibility, relevant_days: relevant_days,
                                  facility_types: facility_types, subscriptions: subscriptions}) do
    [
      edit_faux_link(),
      content_tag :span, class: "trip__card--route-icon" do
        ConciergeSite.IconViewHelper.icon(:t)
      end,
      content_tag :span, class: "trip__card--route" do
        "Station features"
      end,
      content_tag :div, class: "trip__card--type" do
        "#{days(relevant_days)} — #{stops_and_routes(subscriptions)}"
      end,
      content_tag :div, class: "trip__card--type" do
        "#{facility_types(facility_types)}"
      end
    ]
  end

  @spec commute_content(Trip.t) :: [Phoenix.HTML.safe]
  defp commute_content(%Trip{subscriptions: subscriptions, roundtrip: roundtrip, relevant_days: relevant_days,
  start_time: start_time, end_time: end_time, return_start_time: return_start_time,
  return_end_time: return_end_time}) do
    [
      edit_faux_link(),
      routes(subscriptions),
      trip_type(roundtrip, relevant_days),
      trip_times({start_time, end_time}, {return_start_time, return_end_time})
    ]
  end

  @spec routes([Subscription.t]) :: [Phoenix.HTML.safe]
  defp routes(subscriptions) do
    subscriptions
    |> Enum.reject(& &1.return_trip)
    |> collapse_duplicate_green_legs()
    |> Enum.map(fn (subscription) ->
      [
        content_tag :span, class: "trip__card--route-icon" do
          icon(subscription.type, subscription.route)
        end,
        content_tag :span, class: "trip__card--route" do
          route_name(subscription.route)
        end
      ]
    end)
    |> Enum.intersperse(
      content_tag :span, class: "trip__card--route-deliminator" do
        ">"
      end
    )
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

  @spec trip_type(boolean, [atom]) :: Phoenix.HTML.safe
  defp trip_type(roundtrip?, days) do
    content_tag :div, class: "trip__card--type" do
      "#{roundtrip(roundtrip?)}, #{days(days)}"
    end
  end

  @spec roundtrip(boolean) :: String.t
  defp roundtrip(true), do: "Round-trip"
  defp roundtrip(false), do: "One-way"

  @spec days([atom]) :: String.t
  defp days([:monday, :tuesday, :wednesday, :thursday, :friday]), do: "Weekdays"
  defp days([:saturday, :sunday]), do: "Weekends"
  defp days(days) do
    days
    |> Enum.map(& Kernel.<>(String.capitalize(Atom.to_string(&1)), "s"))
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
      "#{format_time(start_time)} / #{format_time(end_time)}"
    end
  end

  @spec format_time({Time.t, Time.t}) :: String.t
  defp format_time({start_time, end_time}) do
    "#{format_time_string(time_to_string(start_time), "%l:%M%P")} - #{format_time_string(time_to_string(end_time), "%l:%M%P")}"
  end

  @spec facility_types([atom]) :: String.t
  defp facility_types(facility_types) do
    case facility_types do
      [:elevator] -> "Elevators"
      [:escalator] -> "Escalators"
      [_, _] -> "Elevators and escalators"
    end
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

  @spec edit_faux_link() :: Phoenix.HTML.safe
  defp edit_faux_link() do
    content_tag :span, class: "trip__card--edit-link" do
      [
        "Edit ", content_tag :i, class: "fa fa-edit" do
          ""
        end
      ]
    end
  end
end
