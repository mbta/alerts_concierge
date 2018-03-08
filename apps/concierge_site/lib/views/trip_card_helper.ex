defmodule ConciergeSite.TripCardHelper do

  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import Phoenix.HTML.Link, only: [link: 2]
  import ConciergeSite.TimeHelper, only: [format_time_string: 2, time_to_string: 1]
  alias AlertProcessor.Model.{Trip, Subscription}

  @spec render(Plug.Conn.t, atom | Trip.t) :: Phoenix.HTML.safe
  def render(conn, %Trip{subscriptions: subscriptions, roundtrip: roundtrip, relevant_days: relevant_days,
                   start_time: start_time, end_time: end_time, return_start_time: return_start_time,
                   return_end_time: return_end_time, id: id}) do
    link to: ConciergeSite.Router.Helpers.v2_trip_path(conn, :edit, id), class: "card trip__card" do
      [
        routes(subscriptions),
        trip_type(roundtrip, relevant_days),
        trip_times({start_time, end_time}, {return_start_time, return_end_time})
      ]
    end
  end
  def render(_), do: ""

  @spec routes([Subscription.t]) :: [Phoenix.HTML.safe]
  defp routes(subscriptions) do
    subscriptions
    |> Enum.map(fn (subscription) ->
      [
        content_tag :span, class: "trip__card--route-icon" do
          icon(subscription.type, subscription.route)
        end,
        content_tag :span, class: "trip__card--route" do
          subscription.route
        end
      ]
    end)
    |> Enum.intersperse(
      content_tag :i, class: "fa fa-chevron-right trip__card--route-deliminator" do
        ""
      end
    )
  end

  @spec icon(atom, String.t) :: Phoenix.HTML.safe
  defp icon(:subway, route), do: ConciergeSite.IconViewHelper.icon(String.to_atom(String.downcase(route)))
  defp icon(:commuter_rail, _), do: ConciergeSite.IconViewHelper.icon(:commuter_rail)
  defp icon(:bus, _), do: ConciergeSite.IconViewHelper.icon(:bus)
  defp icon(:ferry, _), do: ConciergeSite.IconViewHelper.icon(:ferry)

  @spec trip_type(boolean, [atom]) :: Phoenix.HTML.safe
  defp trip_type(roundtrip?, days) do
    content_tag :div, class: "trip__card--type my-2" do
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
end
