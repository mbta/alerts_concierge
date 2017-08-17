defmodule ConciergeSite.BusSubscriptionViewTest do
  use ExUnit.Case
  alias ConciergeSite.BusSubscriptionView
  alias AlertProcessor.Model.Route
  import AlertProcessor.Factory

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

    test "it returns an empty map when step is ahead of current page" do
      classes = BusSubscriptionView.progress_step_classes(:trip_type, :preferences)
      assert classes == %{}
    end
  end

  describe "trip_summary_title/1" do
    @params %{
      "departure_start" => "08:45:00",
      "departure_end" => "09:15:00",
      "return_start" => "16:45:00",
      "return_end" => "17:15:00",
      "route" => "741 - 1",
      "saturday" => "true",
      "sunday" => "false",
      "weekday" => "false"
    }

    @route %Route{
      direction_names: ["Outbound", "Inbound"],
      headsigns: %{0 => ["Logan Airport", "Silver Line Way"], 1 => ["South Station"]},
      long_name: "Silver Line SL1",
      order: 0,
      route_id: "741",
      route_type: 3,
      short_name: "SL1",
      stop_list: []
    }

    test "returns title from subscription params for one_way trip_type" do
      params = Map.merge(@params, %{"trip_type" => "one_way"})
      title = Enum.join BusSubscriptionView.trip_summary_title(params, @route), ""

      assert title == "One way Saturday travel on the Silver Line SL1 bus:"
    end

    test "returns title from subscription params for round_trip trip_type" do
      params = Map.merge(@params, %{"trip_type" => "round_trip"})
      title = Enum.join BusSubscriptionView.trip_summary_title(params, @route), ""

      assert title == "Round trip Saturday travel on the Silver Line SL1 bus:"
    end

    test "handles multiple travel times" do
      params = Map.merge(@params, %{"trip_type" => "one_way", "weekday": "true"})
      title = Enum.join BusSubscriptionView.trip_summary_title(params, @route), ""

      assert title == "One way Saturday travel on the Silver Line SL1 bus:"
    end
  end

  describe "trip_summary_routes/1" do
    test "returns summary of routes for one way" do
      params = Map.merge(@params, %{"trip_type" => "one_way"})
      [route] = BusSubscriptionView.trip_summary_routes(params)

      assert IO.iodata_to_binary(route) =~ "8:45 AM -  9:15 AM | Inbound"
    end

    test "returns summary of routes for round trip" do
      params = Map.merge(@params, %{"trip_type" => "round_trip"})
      [inbound, outbound] = BusSubscriptionView.trip_summary_routes(params)

      assert IO.iodata_to_binary(inbound) =~ "8:45 AM -  9:15 AM | Inbound"
      assert IO.iodata_to_binary(outbound) =~ "4:45 PM -  5:15 PM | Outbound"
    end
  end

  describe "route_name/1" do
    test "returns full route name with direction" do
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.put(:informed_entities, bus_subscription_entities())

      assert "Route 57A Outbound" == BusSubscriptionView.route_name(subscription) |> IO.iodata_to_binary()
    end
  end
end
