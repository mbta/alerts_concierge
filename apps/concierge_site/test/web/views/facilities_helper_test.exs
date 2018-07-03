defmodule ConciergeSite.FacilitiesHelperTest do
  use ConciergeSite.ConnCase
  alias ConciergeSite.FacilitiesHelper
  alias AlertProcessor.Model.Trip

  setup do
    trip_with_escalator = %Trip{
      id: Ecto.UUID.generate(),
      alert_priority_type: :low,
      relevant_days: [:monday],
      start_time: ~T[09:00:00],
      end_time: ~T[10:00:00],
      roundtrip: false,
      facility_types: [:elevator, :escalator, :parking_area]
    }
    
    trip_without_escalator = %Trip{
      id: Ecto.UUID.generate(),
      alert_priority_type: :low,
      relevant_days: [:monday],
      start_time: ~T[09:00:00],
      end_time: ~T[10:00:00],
      roundtrip: false,
      facility_types: [:elevator, :parking_area]
    }

    {:ok, trips: [trip_with_escalator, trip_without_escalator]}
  end

  test "checkbox_label_class/2", %{trips: [trip_with_escalator, trip_without_escalator]} do
    assert FacilitiesHelper.checkbox_label_class(trip_with_escalator, :escalator) == "btn btn-outline-primary btn__radio--toggle btn__radio--toggle-item-connected active"
    assert FacilitiesHelper.checkbox_label_class(trip_without_escalator, :escalator) == "btn btn-outline-primary btn__radio--toggle btn__radio--toggle-item-connected"
  end

  test "facility_type_value/2", %{trips: [trip_with_escalator, trip_without_escalator]} do
    assert FacilitiesHelper.facility_type_value(trip_with_escalator, :escalator) == "true"
    assert FacilitiesHelper.facility_type_value(trip_without_escalator, :escalator) == "false"
  end
end
