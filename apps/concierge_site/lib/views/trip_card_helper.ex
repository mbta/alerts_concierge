defmodule ConciergeSite.TripCardHelper do
  @moduledoc """
  Display our Trip Card in templates
  """
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML.Link, only: [link: 2]
  import Phoenix.Controller, only: [get_csrf_token: 0]
  import ConciergeSite.TimeHelper, only: [format_time_string: 2, time_to_string: 1]
  alias AlertProcessor.Model.{Trip, Subscription}
  alias ConciergeSite.{FontAwesomeHelpers, IconViewHelper, RouteHelper}

  @station_features [
    elevator: "Elevators",
    escalator: "Escalators",
    bike_storage: "Bike storage",
    parking_area: "Parking"
  ]

  @spec render(Plug.Conn.t(), atom | Trip.t()) :: Phoenix.HTML.safe()
  def render(conn, %Trip{trip_type: :accessibility, id: id} = trip) do
    content_tag :div,
      class: "card trip__card #{paused_class(trip)}",
      data: [trip_card: "link", link_type: "accessibility", trip_id: id] do
      accessibility_content(trip, conn, id)
    end
  end

  def render(conn, %Trip{id: id} = trip) do
    content_tag :div,
      class: "card trip__card #{paused_class(trip)}",
      data: [trip_card: "link", link_type: "commute", trip_id: id] do
      commute_content(trip, conn, id)
    end
  end

  def render(_), do: ""

  @spec display(Plug.Conn.t(), atom | Trip.t()) :: Phoenix.HTML.safe()
  def display(conn, %Trip{trip_type: :accessibility, id: id} = trip) do
    content_tag :div, class: "card trip__card trip__card--display #{paused_class(trip)}" do
      accessibility_content(trip, conn, id)
    end
  end

  def display(_), do: ""

  @spec accessibility_content(Trip.t(), Plug.Conn.t(), String.t()) :: [Phoenix.HTML.safe()]
  defp accessibility_content(
         %Trip{
           trip_type: :accessibility,
           relevant_days: relevant_days,
           facility_types: facility_types,
           subscriptions: subscriptions
         } = trip,
         conn,
         id
       ) do
    [
      content_tag :div, class: "trip__card--top" do
        [
          content_tag :span, class: "trip__card--route-icon" do
            IconViewHelper.icon(:t)
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
          content_tag :div, class: "trip__card--type" do
            "#{facility_types(facility_types)}"
          end,
          content_tag :div, class: "trip__card--type" do
            "#{days(relevant_days)}"
          end
        ]
      end,
      footer(conn, :accessibility, id, Trip.paused?(trip))
    ]
  end

  @spec commute_content(Trip.t(), Plug.Conn.t(), String.t()) :: [Phoenix.HTML.safe()]
  defp commute_content(
         %Trip{
           subscriptions: subscriptions,
           roundtrip: roundtrip,
           relevant_days: relevant_days,
           start_time: start_time,
           end_time: end_time,
           return_start_time: return_start_time,
           return_end_time: return_end_time,
           facility_types: facility_types
         } = trip,
         conn,
         id
       ) do
    [
      content_tag :div, class: "trip__card--top" do
        [
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
          content_tag :div, class: "trip__card--type" do
            "#{facility_types(facility_types)}"
          end,
          days(relevant_days),
          trip_times({start_time, end_time}, {return_start_time, return_end_time})
        ]
      end,
      footer(conn, :commute, id, Trip.paused?(trip))
    ]
  end

  @spec footer(Plug.Conn.t(), atom, String.t(), boolean) :: Phoenix.HTML.safe()
  defp footer(conn, trip_type, id, trip_paused?) do
    content_tag :div, class: "trip__card--footer" do
      [
        delete_link(id),
        edit_link(conn, trip_type, id),
        pause_link(conn, id, trip_paused?)
      ]
    end
  end

  @spec routes([Subscription.t()]) :: [Phoenix.HTML.safe()]
  defp routes(subscriptions) do
    subscriptions
    |> exclude_return_trip_subscriptions()
    |> RouteHelper.collapse_duplicate_green_legs()
    |> Enum.map(fn subscription ->
      content_tag :div, class: "trip__card--route-container" do
        [
          content_tag :span, class: "trip__card--route-icon" do
            IconViewHelper.icon_for_route(subscription.type, subscription.route)
          end,
          content_tag :span, class: "trip__card--route" do
            RouteHelper.route_name(subscription.route)
          end
        ]
      end
    end)
  end

  @spec stops([Subscription.t()]) :: Phoenix.HTML.safe()
  defp stops(subscriptions) do
    first_trip_subscriptions =
      subscriptions
      |> exclude_return_trip_subscriptions()

    origin = List.first(first_trip_subscriptions).origin
    destination = List.last(first_trip_subscriptions).destination

    content_tag :span, class: "trip__card--stops" do
      case {origin, destination} do
        {nil, nil} ->
          ""

        {nil, destination} ->
          [" to ", RouteHelper.stop_name(destination)]

        {origin, nil} ->
          [" from ", RouteHelper.stop_name(origin)]

        {origin, destination} ->
          ": #{RouteHelper.stop_name(origin)} — #{RouteHelper.stop_name(destination)}"
      end
    end
  end

  @spec roundtrip(boolean) :: String.t()
  defp roundtrip(true), do: "Round-trip"
  defp roundtrip(false), do: "One-way"

  @spec days([atom]) :: String.t()
  defp days([:monday, :tuesday, :wednesday, :thursday, :friday]), do: "Weekdays"
  defp days([:saturday, :sunday]), do: "Weekends"

  defp days([:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]),
    do: "Every day"

  defp days(days) do
    Enum.map_join(days, ", ", &String.slice(String.capitalize(Atom.to_string(&1)), 0..2))
  end

  @spec trip_times({Time.t(), Time.t()}, {Time.t(), Time.t()} | {nil, nil}) :: Phoenix.HTML.safe()
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

  @spec format_time({Time.t(), Time.t()}) :: String.t()
  defp format_time({start_time, end_time}) do
    [start_time, end_time]
    |> Stream.map(&time_to_string/1)
    |> Stream.map(&format_time_string(&1, "%l:%M%p"))
    |> Stream.map(&String.trim(&1, "M"))
    |> Enum.join(" - ")
  end

  @spec facility_types([atom]) :: String.t()
  defp facility_types(facility_types) do
    Enum.map_join(facility_types, ", ", &@station_features[&1])
  end

  @spec stops_and_routes([Subscription.t()]) :: [String.t()]
  defp stops_and_routes(subscriptions) do
    subscriptions
    |> Enum.map(fn subscription ->
      case {subscription.origin, subscription.route} do
        {stop_id, nil} -> RouteHelper.stop_name(stop_id)
        {nil, route_id} -> RouteHelper.route_name(route_id)
      end
    end)
    |> Enum.intersperse(", ")
  end

  @spec delete_link(String.t()) :: Phoenix.HTML.safe()
  defp delete_link(trip_id) do
    content_tag :a,
      class: "trip__card--delete-link",
      tabindex: "0",
      data: [toggle: "modal", target: "#deleteModal", trip_id: trip_id, token: get_csrf_token()] do
      [
        "Delete",
        FontAwesomeHelpers.fa("trash")
      ]
    end
  end

  @spec edit_link(Plug.Conn.t(), atom, String.t()) :: Phoenix.HTML.safe()
  defp edit_link(conn, :commute, id) do
    conn
    |> ConciergeSite.Router.Helpers.trip_path(:edit, id)
    |> edit_link_for_path()
  end

  defp edit_link(conn, :accessibility, id) do
    conn
    |> ConciergeSite.Router.Helpers.accessibility_trip_path(:edit, id)
    |> edit_link_for_path()
  end

  @spec edit_link_for_path(String.t()) :: Phoenix.HTML.safe()
  defp edit_link_for_path(path) do
    link to: path, class: "trip__card--edit-link" do
      [
        "Edit",
        FontAwesomeHelpers.fa("pencil")
      ]
    end
  end

  @spec pause_link(Plug.Conn.t(), String.t(), boolean) :: Phoenix.HTML.safe()
  defp pause_link(conn, trip_id, false = trip_paused?) do
    conn
    |> ConciergeSite.Router.Helpers.trip_pause_path(:pause, trip_id)
    |> pause_link_for_path(trip_paused?)
  end

  defp pause_link(conn, trip_id, true = trip_paused?) do
    conn
    |> ConciergeSite.Router.Helpers.trip_resume_path(:resume, trip_id)
    |> pause_link_for_path(trip_paused?)
  end

  @spec pause_link_for_path(String.t(), boolean) :: Phoenix.HTML.safe()
  defp pause_link_for_path(path, trip_paused?) do
    link to: path, method: :patch, class: "trip__card--pause-link" do
      pause_link_content(trip_paused?)
    end
  end

  @spec pause_link_content(boolean) :: [Phoenix.HTML.safe()]
  defp pause_link_content(false = _trip_paused?) do
    [
      "Pause",
      FontAwesomeHelpers.fa("pause-circle")
    ]
  end

  defp pause_link_content(true = _trip_paused?) do
    [
      "Resume",
      FontAwesomeHelpers.fa("play-circle")
    ]
  end

  defp exclude_return_trip_subscriptions(subscriptions) do
    subscriptions
    |> Enum.reject(& &1.return_trip)
  end

  @spec paused_class(Trip.t()) :: String.t()
  defp paused_class(%Trip{} = trip), do: if(Trip.paused?(trip), do: "paused", else: "")
end
