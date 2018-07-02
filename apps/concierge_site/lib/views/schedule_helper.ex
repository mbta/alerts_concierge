defmodule ConciergeSite.ScheduleHelper do
  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.Route
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import ConciergeSite.TimeHelper, only: [format_time_string: 2, time_to_string: 1]

  @spec render(map, String.t, String.t) :: Phoenix.HTML.safe
  def render(schedules, start_field_id, end_field_id) do
    content_tag :div, id: id(start_field_id), class: "schedules__container", data: [type: "schedule-viewer", start: start_field_id, end: end_field_id] do
      for {{mode, route_id}, schedule} <- schedules do
        {:ok, route} = ServiceInfoCache.get_route(route_id)
        do_route_schedule(mode, Route.name(route), schedule)
      end
    end
  end

  defp id("trip_start_time"), do: "schedule_start"
  defp id("trip_return_start_time"), do: "schedule_return"

  defp do_route_schedule(mode, route_name, schedule) do
    [
      content_tag :div, class: "schedules__trips--leg" do
        [
          content_tag :p, class: "schedules__header" do
            "Which #{header(mode)} would you like alerts about?"
          end,
          content_tag :p, class: "schedules__blankslate" do
            "#{blank_slate(mode)}"
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

  defp blank_slate("cr"), do: "No trains scheduled during this time period."
  defp blank_slate("ferry"), do: "No boats scheduled during this time period."

  defp trip("cr", trip) do
    [ConciergeSite.IconViewHelper.icon(:commuter_rail), "Train #{trip.trip_number}, #{elem(trip.origin, 0)}, #{format_time_string(time_to_string(trip.departure_time), "%l:%M%P")}"]
  end
  defp trip("ferry", trip) do
    [ConciergeSite.IconViewHelper.icon(:ferry), "#{elem(trip.origin, 0)}, #{format_time_string(time_to_string(trip.departure_time), "%l:%M%P")}"]
  end
end
