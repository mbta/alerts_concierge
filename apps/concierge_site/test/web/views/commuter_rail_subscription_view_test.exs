defmodule ConciergeSite.CommuterRailSubscriptionViewTest do
  use ExUnit.Case
  alias ConciergeSite.CommuterRailSubscriptionView

  describe "progress_link_class" do
    test "it returns the disabled class when the page is trip_type" do
      class = CommuterRailSubscriptionView.progress_link_class(:trip_type, :trip_info)
      assert class == "disabled-progress-link"
    end

    test "it returns the disabled class when the page/step are included in disabled_progress_bar_links" do
      class = CommuterRailSubscriptionView.progress_link_class(:trip_info, :preferences)
      assert class == "disabled-progress-link"
    end

    test "it returns nil otherwise" do
      class = CommuterRailSubscriptionView.progress_link_class(:trip_info, :trip_type)
      assert class == nil
    end
  end

  describe "progress_step_classes" do

    @active_classes %{circle: "active-circle", name: "active-page"}

    test "it returns a map of active classes when step and page are equal" do
      classes = CommuterRailSubscriptionView.progress_step_classes(:trip_info, :trip_info)
      assert classes == @active_classes
    end

    test "it returns an empty map when step is ahead of current page" do
      classes = CommuterRailSubscriptionView.progress_step_classes(:trip_type, :preferences)
      assert classes == %{}
    end
  end

  describe "trip_summary_details" do
    test " it returns the correct details for one_way" do
      params = %{
        "trip_type" => "one_way",
        "relevant_days" => "weekday",
        "trips" => ["123", "345"]
      }
      destination = {"Newburyport", "Newburyport", {1, 1}, 1}
      origin = {"North Station", "place-north", {1, 1}, 1}
      details = CommuterRailSubscriptionView.trip_summary_details(params, origin, destination)
      assert IO.iodata_to_binary(details) == "2 weekday trains from North Station to Newburyport"
    end

    test "it returns the correct details for round_trip" do
      params = %{
        "trip_type" => "round_trip",
        "relevant_days" => "sunday",
        "trips" => ["123", "345"],
        "return_trips" => ["234"]
      }
      destination = {"Newburyport", "Newburyport", {1, 1}, 1}
      origin = {"North Station", "place-north", {1, 1}, 1}

      [safe: depart, safe: return] =
        CommuterRailSubscriptionView.trip_summary_details(params, origin, destination)

      assert IO.iodata_to_binary(depart) =~ "2 Sunday trains from North Station to Newburyport"
      assert IO.iodata_to_binary(return) =~ "1 Sunday train from Newburyport to North Station"
    end
  end
end
