defmodule ConciergeSite.ScheduleHelper do
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import ConciergeSite.TimeHelper, only: [format_time_string: 2, time_to_string: 1]

  @spec render(map, String.t, String.t) :: Phoenix.HTML.safe
  def render(schedules, start_field_id, end_field_id) do
    content_tag :div, class: "schedules__container", data: [type: "schedule-viewer", start: start_field_id, end: end_field_id] do
      for {{mode, route}, schedule} <- schedules do
        do_route_schedule(mode, route, schedule)
      end
    end
  end

  defp do_route_schedule(mode, route, schedule) do
    [
      content_tag :div, class: "schedules__trips--leg" do
        [
          content_tag :p, class: "schedules__header" do
            "#{header(mode)} scheduled in this time for #{route}"
          end,
          content_tag :ul, class: "schedules__trips--container" do
            for trip <- schedule do
              content_tag :li, class: "schedules__trips--item", data: [time: trip.departure_time] do
                trip(mode, trip)
              end
            end
          end
        ]
      end
    ]
  end

  defp header("cr"), do: "Commuter Rail trains"
  defp header("ferry"), do: "Ferry boats"

  defp trip("cr", trip) do
    [ConciergeSite.IconViewHelper.icon(:commuter_rail), "Train #{trip.trip_number}, #{elem(trip.origin, 0)}, #{format_time_string(time_to_string(trip.departure_time), "%l:%M%P")}"]
  end
  defp trip("ferry", trip) do
    [ConciergeSite.IconViewHelper.icon(:ferry), "#{elem(trip.origin, 0)}, #{format_time_string(time_to_string(trip.departure_time), "%l:%M%P")}"]
  end
end
