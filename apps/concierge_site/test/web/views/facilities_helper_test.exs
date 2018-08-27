defmodule ConciergeSite.FacilitiesHelperTest do
  use ConciergeSite.ConnCase, async: true
  alias ConciergeSite.FacilitiesHelper
  alias AlertProcessor.Model.Trip

  describe "facility_checkbox/4" do
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

      checked_escalator_html =
        Phoenix.HTML.safe_to_string(
          FacilitiesHelper.facility_checkbox(
            :mock_form,
            trip_with_escalator,
            :escalator,
            "Escalators"
          )
        )

      unchecked_escalator_html =
        Phoenix.HTML.safe_to_string(
          FacilitiesHelper.facility_checkbox(
            :mock_form,
            trip_without_escalator,
            :escalator,
            "Escalators"
          )
        )

      {:ok, outputs: [checked_escalator_html, unchecked_escalator_html]}
    end

    test "active class on label", %{outputs: [checked_escalator_html, unchecked_escalator_html]} do
      assert checked_escalator_html =~ "active"
      refute unchecked_escalator_html =~ "active"
    end

    test "name", %{outputs: [checked_escalator_html, unchecked_escalator_html]} do
      assert checked_escalator_html =~ "Escalators"
      assert unchecked_escalator_html =~ "Escalators"
    end

    test "icon", %{outputs: [checked_escalator_html, unchecked_escalator_html]} do
      assert checked_escalator_html =~ "Icon/Facilities/Escalator"
      assert unchecked_escalator_html =~ "Icon/Facilities/Escalator"
    end

    test "checked", %{outputs: [checked_escalator_html, unchecked_escalator_html]} do
      assert checked_escalator_html =~ ~r/<input.*escalator.*value=\"true\".*checked.*?>/
      refute unchecked_escalator_html =~ ~r/<input.*escalator.*value=\"true\".*checked.*?>/
    end
  end
end
