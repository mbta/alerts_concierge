defmodule ConciergeSite.FacilitiesHelper do
  alias AlertProcessor.Model.Trip

  def checkbox_label_class(trip, facility_type) do
    base_class = "btn btn-outline-primary btn__radio--toggle btn__radio--toggle-item-connected"
    active_class = if includes_facility_type(trip, facility_type) do
      " active"
    else
      ""
    end
    base_class <> active_class
  end

  def facility_type_value(trip, type) do
    to_string(includes_facility_type(trip, type))
  end

  defp includes_facility_type(%Trip{facility_types: facility_types}, type) do
    cond do
      is_list(facility_types) ->
        type in facility_types
      true ->
        false
    end
  end
end
