defmodule ConciergeSite.BusSubscriptionViewTest do
  use ExUnit.Case
  alias ConciergeSite.BusSubscriptionView

  describe "progress_link_class" do
    test "it returns the disabled class when the page is trip_type" do
      class = BusSubscriptionView.progress_link_class(:trip_type, :trip_info)
      assert class == "disabled-progress-link"
    end

    test "it returns the disabled class when the page/step are included in disabled_progress_bar_links" do
      class = BusSubscriptionView.progress_link_class(:trip_info, :preferences)
      assert class == "disabled-progress-link"
    end

    test "it returns nil otherwise" do
      class = BusSubscriptionView.progress_link_class(:trip_info, :trip_type)
      assert class == nil
    end
  end

  describe "progress_step_classes" do

    @active_classes %{circle: "active-circle", name: "active-page"}

    test "it returns a map of active classes when step and page are equal" do
      classes = BusSubscriptionView.progress_step_classes(:trip_info, :trip_info)
      assert classes == @active_classes
    end

    test "it returns an empty map when step and page are different" do
      classes = BusSubscriptionView.progress_step_classes(:preferences, :trip_type)
      assert classes == %{}
    end
  end

  describe "trip_summary_title/1" do
    @params %{
      "departure_start" => "08:45:00",
      "departure_end" => "09:15:00",
      "return_start" => "16:45:00",
      "return_end" => "17:15:00",
      "route" => "Silver Line SL1 - Inbound",
      "saturday" => "true",
      "sunday" => "false",
      "weekday" => "false"
    }

    test "returns title from subscription params for one_way trip_type" do
      params = Map.merge(@params, %{"trip_type" => "one_way"})
      title = Enum.join BusSubscriptionView.trip_summary_title(params), ""

      assert title == "One way Saturday travel on the Silver Line SL1 bus:"
    end

    test "returns title from subscription params for round_trip trip_type" do
      params = Map.merge(@params, %{"trip_type" => "round_trip"})
      title = Enum.join BusSubscriptionView.trip_summary_title(params), ""

      assert title == "Round trip Saturday travel on the Silver Line SL1 bus:"
    end

    test "handles multiple travel times" do
      params = Map.merge(@params, %{"trip_type" => "one_way", "weekday": "true"})
      title = Enum.join BusSubscriptionView.trip_summary_title(params), ""

      assert title == "One way Saturday travel on the Silver Line SL1 bus:"
    end
  end

  describe "trip_summary_routes/1" do
    test "returns summary of routes for one way" do
      params = Map.merge(@params, %{"trip_type" => "one_way"})
      routes = BusSubscriptionView.trip_summary_routes(params)

      assert routes == [["08:45 AM", " - ", "09:15 AM", " | ", "Inbound"]]
    end

    test "returns summary of routes for round trip" do
      params = Map.merge(@params, %{"trip_type" => "round_trip"})
      routes = BusSubscriptionView.trip_summary_routes(params)

      assert routes == [["08:45 AM", " - ", "09:15 AM", " | ", "Inbound"], ["04:45 PM", " - ", "05:15 PM", " | ", "Outbound"]]
    end
  end
end
