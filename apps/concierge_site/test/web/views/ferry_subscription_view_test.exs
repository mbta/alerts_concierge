defmodule ConciergeSite.FerrySubscriptionViewTest do
  use ExUnit.Case
  alias ConciergeSite.FerrySubscriptionView

  describe "progress_link_class" do
    test "it returns the disabled class when the page is trip_type" do
      class = FerrySubscriptionView.progress_link_class(:trip_type, :trip_info)
      assert class == "disabled-progress-link"
    end

    test "it returns the disabled class when the page/step are included in disabled_progress_bar_links" do
      class = FerrySubscriptionView.progress_link_class(:trip_info, :preferences)
      assert class == "disabled-progress-link"
    end

    test "it returns nil otherwise" do
      class = FerrySubscriptionView.progress_link_class(:trip_info, :trip_type)
      assert class == nil
    end
  end

  describe "progress_step_classes" do

    @active_classes %{circle: "active-circle", name: "active-page"}

    test "it returns a map of active classes when step and page are equal" do
      classes = FerrySubscriptionView.progress_step_classes(:trip_info, :trip_info)
      assert classes == @active_classes
    end

    test "it returns an empty map when step is ahead of current page" do
      classes = FerrySubscriptionView.progress_step_classes(:trip_type, :preferences)
      assert classes == %{}
    end
  end

  describe "trip_summary_details/3" do
    test "returns a summary for a one way ferry trip" do
      origin = {"Charlestown Navy Yard", ""}
      destination = {"Long Wharf, Boston", ""}

      subscription_params = %{
        "trip_type" => "one_way",
        "trips" => ["Boat-F4-Boat-Charlestown-08:00:00-weekday-1"],
        "relevant_days" => "weekday"
      }

      summary = FerrySubscriptionView.trip_summary_details(subscription_params, origin, destination)

      assert IO.iodata_to_binary(summary) == "1 weekday ferry from Charlestown Navy Yard to Long Wharf, Boston"
    end

    test "returns a summary for a round trip" do
      origin = {"Charlestown Navy Yard", ""}
      destination = {"Long Wharf, Boston", ""}

      subscription_params = %{
        "trip_type" => "round_trip",
        "trips" => ["Boat-F4-Boat-Charlestown-08:00:00-weekday-1"],
        "return_trips" => ["Boat-F4-Boat-Long-17:00:00-weekday-0"],
        "relevant_days" => "weekday"
      }

      [safe: depart, safe: return] =
        FerrySubscriptionView.trip_summary_details(subscription_params, origin, destination)

      assert IO.iodata_to_binary(depart) =~ "1 weekday ferry from Charlestown Navy Yard to Long Wharf, Boston"
      assert IO.iodata_to_binary(return) =~ "1 weekday ferry from Long Wharf, Boston to Charlestown Navy Yard"
    end
  end
end
