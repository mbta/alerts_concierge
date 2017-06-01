defmodule ConciergeSite.SubwaySubscriptionViewTest do
  use ExUnit.Case
  alias ConciergeSite.SubwaySubscriptionView

  describe "progress_link_class" do
    test "it returns the disabled class when the page is trip_type" do
      class = SubwaySubscriptionView.progress_link_class(:trip_type, :trip_info)
      assert class == "disabled-progress-link"
    end

    test "it returns the disabled class when the page/step are included in disabled_progress_bar_links" do
      class = SubwaySubscriptionView.progress_link_class(:trip_info, :preferences)
      assert class == "disabled-progress-link"
    end

    test "it returns nil otherwise" do
      class = SubwaySubscriptionView.progress_link_class(:trip_info, :trip_type)
      assert class == nil
    end
  end

  describe "progress_step_classes" do

    @active_classes %{circle: "active-circle", name: "active-page"}

    test "it returns a map of active classes when step and page are equal" do
      classes = SubwaySubscriptionView.progress_step_classes(:trip_info, :trip_info)
      assert classes == @active_classes
    end

    test "it returns an empty map when step and page are different" do
      classes = SubwaySubscriptionView.progress_step_classes(:preferences, :trip_type)
      assert classes == %{}
    end
  end

  describe "station_select_list_options" do
    test "changes a map of lines into a select helper friendly list" do
      stations = %{{"Blue", 1} => [], {"Green", 0} => [], {"Red", 0} => []}
      select_options = SubwaySubscriptionView.station_list_select_options(stations)

      assert select_options == [{"Blue", []}, {"Green", []}, {"Red", []}]
    end
  end

  describe "station_suggestion_options" do
    test "it returns a list of station tuples from a map of lines" do
      stations = %{
        {"Blue",1} => [
          {"Bowdoin", "place-bomnl"},
          {"Government Center", "place-gover"},
          {"State Street", "place-state"}
        ]
      }

      suggestion_options = SubwaySubscriptionView.station_suggestion_options(stations)

      assert suggestion_options == [
        {"Bowdoin", "place-bomnl", ["Blue"]},
        {"Government Center", "place-gover", ["Blue"]},
        {"State Street", "place-state", ["Blue"]}
      ]
    end

    test "it combines all the green lines for display purposes" do
      stations = %{
        {"Green-B",1} => [{"Boston College", "place-lake"}],
        {"Green-C",1} => [{"Cleveland Circle", "place-clmnl"}],
        {"Green-D",1} => [{"Riverside", "place-river"}]
      }

      suggestion_options = SubwaySubscriptionView.station_suggestion_options(stations)

      assert suggestion_options == [
        {"Boston College", "place-lake", ["Green"]},
        {"Cleveland Circle", "place-clmnl", ["Green"]},
        {"Riverside", "place-river", ["Green"]}
      ]
    end

    test "it merges stations on multiple lines" do
      stations = %{
        {"Red",1} => [{"Park Street", "place-pktrm"}],
        {"Green-C",1} => [{"Park Street", "place-pktrm"}],
        {"Green-D",1} => [{"Park Street", "place-pktrm"}]
      }

      suggestion_options = SubwaySubscriptionView.station_suggestion_options(stations)

      assert suggestion_options == [{"Park Street", "place-pktrm", ["Green", "Red"]}]
    end
  end
end
