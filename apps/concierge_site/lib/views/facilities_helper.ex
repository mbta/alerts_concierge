defmodule ConciergeSite.FacilitiesHelper do
  import Phoenix.HTML.Tag, only: [content_tag: 2]
  import Phoenix.HTML.Form, only: [label: 2, checkbox: 3]
  import Phoenix.View, only: [render: 3]
  alias AlertProcessor.Model.Trip

  @spec facility_checkbox(Phoenix.HTML.Form.t() | atom, Trip.t(), atom, String.t()) ::
          Phoenix.HTML.safe()
  def facility_checkbox(form, trip, facility_type, name) do
    label role: "checkbox", class: checkbox_label_class(trip, facility_type), tabindex: "0" do
      checkbox_content(form, trip, facility_type, name)
    end
  end

  defp checkbox_label_class(trip, facility_type) do
    base_class = "btn btn-outline-primary btn__radio--toggle btn__radio--toggle-item-connected"

    active_class =
      if includes_facility_type(trip, facility_type) do
        " active"
      else
        ""
      end

    base_class <> active_class
  end

  defp checkbox_content(form, trip, facility_type, name) do
    [
      icon(facility_type),
      checkbox(
        form,
        facility_type,
        value: facility_type_value(trip, facility_type),
        tabindex: "-1"
      ),
      content_tag(:div, name)
    ]
  end

  defp icon(:bike_storage), do: render(ConciergeSite.LayoutView, "_icon_bike.html", %{})
  defp icon(:parking_area), do: render(ConciergeSite.LayoutView, "_icon_parking.html", %{})

  defp icon(facility_type),
    do: render(ConciergeSite.LayoutView, "_icon_#{to_string(facility_type)}.html", %{})

  defp facility_type_value(trip, type) do
    to_string(includes_facility_type(trip, type))
  end

  defp includes_facility_type(%Trip{facility_types: facility_types}, type) do
    if is_list(facility_types) do
      type in facility_types
    else
      false
    end
  end
end
