defmodule ConciergeSite.ScheduleHelper do
  alias AlertProcessor.ServiceInfoCache
  alias AlertProcessor.Model.Route
  import Phoenix.HTML.Tag, only: [content_tag: 3, content_tag: 2, tag: 2]
  import ConciergeSite.TimeHelper, only: [format_time_string: 2, time_to_string: 1]

  @spec render(map, String.t, String.t) :: Phoenix.HTML.safe
  def render(schedules, start_field_id, end_field_id) do
    id = id(start_field_id)
    content_tag :div, id: id, class: "schedules__container", data: [type: "schedule-viewer", start: start_field_id, end: end_field_id] do
      for {{mode, route_id}, schedule} <- schedules do
        do_route_schedule(mode, id, schedule)
      end
    end
  end

  defp id("trip_start_time"), do: "schedule_start"
  defp id("trip_return_start_time"), do: "schedule_return"

  defp do_route_schedule(mode, id, schedule) do
    [
      content_tag :div, class: "schedules__trips--leg", data: [type: "schedule-leg"] do
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
                trip(mode, id, trip)
              end
            end
          end,
          content_tag :div, class: "error-block-container", data: [type: "leg-error"] do
            content_tag :span, class: "error-block" do
              "Select at least one #{vehicle(mode)} from the list."
            end
          end
        ]
      end
    ]
  end

  defp vehicle("cr"), do: "train"
  defp vehicle("ferry"), do: "boat"

  defp header("cr"), do: "Commuter Rail trains"
  defp header("ferry"), do: "Ferry boats"

  defp blank_slate("cr"), do: "No trains scheduled during this time period."
  defp blank_slate("ferry"), do: "No boats scheduled during this time period."

  defp trip("cr", id, trip) do
    content_tag :label, role: "checkbox", tabindex: "0", aria: [checked: "false"],
                        class: "btn btn-outline-primary btn__radio--toggle" do
      [
        tag(:input, name: "trip[#{id}][#{trip.route.route_id}][]", type: "checkbox", tabindex: "-1", value: trip.departure_time),
        content_tag :div do
          [
            ConciergeSite.IconViewHelper.icon(:commuter_rail),
            "Train #{trip.trip_number} from #{elem(trip.origin, 0)}, #{format_time_string(time_to_string(trip.departure_time), "%l:%M%P")}"
          ]
        end,
        content_tag :i, class: "fa fa-check" do
          ""
        end
      ]
    end
  end
  defp trip("ferry", id, trip) do
    content_tag :label, role: "checkbox", tabindex: "0", aria: [checked: "false"],
                        class: "btn btn-outline-primary btn__radio--toggle" do
      [
        tag(:input, name: "trip[#{id}][#{trip.route.route_id}][]", type: "checkbox", tabindex: "-1", value: trip.departure_time),
        content_tag :div do
          [
            ConciergeSite.IconViewHelper.icon(:ferry),
            "#{elem(trip.origin, 0)} from #{format_time_string(time_to_string(trip.departure_time), "%l:%M%P")}"
          ]
        end,
        content_tag :i, class: "fa fa-check" do
          ""
        end
      ]
    end
  end
end