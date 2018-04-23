defmodule ConciergeSite.DaySelectHelper do
  import Phoenix.HTML.Tag, only: [content_tag: 3, tag: 2]

  @weekdays ["monday", "tuesday", "wednesday", "thursday", "friday"]
  @weekend ["saturday", "sunday"]
  @days @weekdays ++ @weekend
  @short_days ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

  @spec render(atom) :: Phoenix.HTML.safe
  def render(input_name, checked \\ []) do
    checked_set = prepare_checked_set(checked)
    content_tag :div, class: "day-selector", data: [selector: "date"] do
      [title(), day(input_name, checked_set), group(checked_set)]
    end
  end

  defp prepare_checked_set(checked) do
    checked
    |> ensure_days_as_string()
    |> MapSet.new()
    |> if_needed_add_weekday()
    |> if_needed_add_weekend()
  end

  defp ensure_days_as_string([]), do: []

  defp ensure_days_as_string(days), do: Enum.map(days, &ensure_day_as_string/1)

  defp ensure_day_as_string(day) when is_atom(day), do: Atom.to_string(day)

  defp ensure_day_as_string(day) when is_binary(day), do: day

  defp if_needed_add_weekday(checked) do
    if MapSet.subset?(MapSet.new(@weekdays), checked) do
      MapSet.put(checked, "weekdays")
    else
      checked
    end
  end

  defp if_needed_add_weekend(checked) do
    if MapSet.subset?(MapSet.new(@weekend), checked) do
      MapSet.put(checked, "weekend")
    else
      checked
    end
  end

  defp title do
    content_tag :div, class: "title-part" do
      Enum.map(@short_days, & content_tag(:div, &1, class: "day-header"))
    end
  end

  defp day(input_name, checked_set) do
    content_tag :div, class: "day-part" do
      content_tag :div, class: "btn-group btn-group-toggle" do
        Enum.map(@days, & label(input_name, &1, Enum.member?(checked_set, &1)))
      end
    end
  end

  defp label(input_name, day, selected?) do
    content_tag :label, class: label_class(selected?) do
      [tag(:input, type: "checkbox", autocomplete: "off", value: day,
           name: "#{input_name}[relevant_days][]", checked: selected?),
       check_icon(selected?)]
    end
  end

  defp check_icon(true), do: content_tag(:i, "", class: "fa fa-check")
  defp check_icon(_), do: content_tag(:i, "", class: "fa")

  defp label_class(true), do: "btn btn-day active"
  defp label_class(_), do: "btn btn-day"

  defp group(checked_set) do
    content_tag :div, class: "group-part invisible-no-js" do
      content_tag :div, class: "btn-group btn-group-toggle" do
        Enum.map(["weekdays", "weekend"], & group_label(&1, Enum.member?(checked_set, &1)))
      end
    end
  end

  defp group_label(name, selected?) do
    content_tag :label, class: "#{label_class(selected?)} btn-#{name}" do
      [tag(:input, type: "checkbox", autocomplete: "off", value: name, checked: selected?),
       String.capitalize(name)]
    end
  end
end