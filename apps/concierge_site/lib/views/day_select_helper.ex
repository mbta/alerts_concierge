defmodule ConciergeSite.DaySelectHelper do
  import Phoenix.HTML.Tag, only: [content_tag: 3, tag: 2]

  @days ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
  @short_days ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

  @spec render(atom) :: Phoenix.HTML.safe
  def render(input_name) do
    content_tag :div, class: "day-selector", data: [selector: "date"] do
      [title(), day(input_name), group()]
    end
  end

  defp title do
    content_tag :div, class: "title-part" do
      Enum.map(@short_days, & content_tag(:div, &1, class: "day-header"))
    end
  end

  defp day(input_name) do
    content_tag :div, class: "day-part" do
      content_tag :div, class: "btn-group btn-group-toggle" do
        Enum.map(@days, & label(input_name, &1))
      end
    end
  end

  defp label(input_name, day) do
    content_tag :label, class: "btn btn-secondary" do
      [tag(:input, type: "checkbox", autocomplete: "off", value: day, name: "#{input_name}[days][]"),
       content_tag(:i, "", class: "fa fa-check")]
    end
  end

  defp group do
    content_tag :div, class: "group-part invisible-no-js" do
      content_tag :div, class: "btn-group btn-group-toggle" do
        [content_tag :label, class: "btn btn-secondary btn-weekdays" do
          [tag(:input, type: "checkbox", autocomplete: "off", value: "weekdays"),
           "Weekdays"]
        end,
          content_tag :label, class: "btn btn-secondary btn-weekend" do
            [tag(:input, type: "checkbox", autocomplete: "off", value: "weekend"),
             "Weekend"]
          end]
      end
    end
  end
end
