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

  describe "trip_summary_header" do
    it "returns the correct header for one_way" do
      params = %{
        "trip_type" => "one_way",
        "relevant_days" => "weekday",
        "trips" => ["123", "345"]
      }
      destination = {"Newburyport", "Newburyport"}
      origin = {"North Station", "place-north"}
      header = CommuterRailSubscriptionView.trip_summary_header(params, origin, destination)
      assert IO.iodata_to_binary(header) == "One way weekday travel between North Station and Newburyport:"
    end

    it "returns the correct header for round_trip" do
      params = %{
        "trip_type" => "round_trip",
        "relevant_days" => "sunday",
        "trips" => ["123", "345"]
      }
      destination = {"Newburyport", "Newburyport"}
      origin = {"North Station", "place-north"}
      header = CommuterRailSubscriptionView.trip_summary_header(params, origin, destination)
      assert IO.iodata_to_binary(header) == "Round trip Sunday travel between North Station and Newburyport:"
    end
  end

  describe "trip_summary_details" do
    it "returns the correct details for one_way" do
      params = %{
        "trip_type" => "one_way",
        "relevant_days" => "weekday",
        "trips" => ["123", "345"]
      }
      destination = {"Newburyport", "Newburyport"}
      origin = {"North Station", "place-north"}
      details = CommuterRailSubscriptionView.trip_summary_details(params, origin, destination)
      assert IO.iodata_to_binary(details) == "2 trains from North Station to Newburyport"
    end

    it "returns the correct details for round_trip" do
      params = %{
        "trip_type" => "round_trip",
        "relevant_days" => "sunday",
        "trips" => ["123", "345"],
        "return_trips" => ["234"]
      }
      destination = {"Newburyport", "Newburyport"}
      origin = {"North Station", "place-north"}
      details = CommuterRailSubscriptionView.trip_summary_details(params, origin, destination)
      assert IO.iodata_to_binary(details) =~ "2 trains from North Station to Newburyport"
      assert IO.iodata_to_binary(details) =~ "1 train from Newburyport to North Station"
    end
  end
end
