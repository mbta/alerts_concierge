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

  describe "trip_summary_routes/2" do
    @params %{
      "departure_start" => "08:45:00",
      "departure_end" => "09:15:00",
      "return_start" => "16:45:00",
      "return_end" => "17:15:00",
      "routes" => ["741 - 1"],
      "saturday" => "true",
      "sunday" => "true",
      "weekday" => "true",
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

    @route2 %Route{
      direction_names: ["Outbound", "Inbound"],
      headsigns: %{0 => ["Arlington Center", "Clarendon Hill"], 1 => ["Lechmere"]},
      long_name: "",
      order: 78,
      route_id: "87",
      route_type: 3,
      short_name: "87",
      stop_list: []
    }

    test "returns summary of routes for one way" do
      params = Map.merge(@params, %{"trip_type" => "one_way"})
      [summary] = BusSubscriptionView.trip_summary_routes(params, [@route])

      assert IO.iodata_to_binary(summary) =~ "Route Silver Line SL1 inbound, Saturday, Sunday, or weekdays  8:45 AM -  9:15 AM"
    end

    test "returns summary of routes for round trip" do
      params = Map.merge(@params, %{"trip_type" => "round_trip"})
      [inbound, outbound] = BusSubscriptionView.trip_summary_routes(params, [@route])

      assert IO.iodata_to_binary(inbound) =~ "Route Silver Line SL1 inbound, Saturday, Sunday, or weekday  8:45 AM -  9:15 AM"
      assert IO.iodata_to_binary(outbound) =~ "Route Silver Line SL1 outbound, Saturday, Sunday, or weekday  4:45 PM -  5:15 PM"
    end

    test "returns summary of routes for round trip for multiple routes" do
      params = Map.merge(@params, %{"trip_type" => "round_trip"})
      [inbound, outbound] = BusSubscriptionView.trip_summary_routes(params, [@route, @route2])

      assert IO.iodata_to_binary(inbound) =~ "2 Bus Routes, Saturday, Sunday, or weekday  8:45 AM -  9:15 AM"
      assert IO.iodata_to_binary(outbound) =~ "2 Bus Routes, Saturday, Sunday, or weekday  4:45 PM -  5:15 PM"
    end
  end

  describe "route_name/1" do
    test "returns full route name with direction" do
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.put(:informed_entities, bus_subscription_entities())

      assert "Route 57A outbound" == subscription |> BusSubscriptionView.route_name() |> IO.iodata_to_binary()
    end

    test "returns n Bus Routes when multiple routes are present" do
      subscription =
        subscription_factory()
        |> bus_subscription()
        |> Map.put(:informed_entities, Enum.uniq(bus_subscription_entities() ++ bus_subscription_entities("87")))

      assert "2 Bus Routes" == subscription |> BusSubscriptionView.route_name() |> IO.iodata_to_binary()
    end
  end
end
