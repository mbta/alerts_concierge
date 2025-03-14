defmodule AlertProcessor.ServiceInfoCacheTest do
  @moduledoc false
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{Model.Route, ServiceInfoCache}

  setup_all do
    {:ok, pid} = ServiceInfoCache.start_link(name: :service_info_cache_test_subway)
    {:ok, pid: pid}
  end

  describe "init/1" do
    test "returns the results of loading initial service info" do
      assert {:ok,
              %{
                routes: [_ | _],
                stops_with_icons: %{},
                commuter_rail_trip_ids: %{},
                facility_map: %{},
                ferry_general_ids: %{},
                parent_stop_info: %{},
                subway_full_routes: [_ | _]
              }} = ServiceInfoCache.init([])
    end
  end

  test "get_subway_info/0 returns subway branch lists", %{pid: pid} do
    {:ok, route_info} = ServiceInfoCache.get_subway_info(pid)

    assert [
             %Route{
               route_id: "Blue",
               long_name: "Blue Line",
               route_type: 1,
               direction_names: ["West", "East"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Green-B",
               long_name: "Green Line B",
               route_type: 0,
               direction_names: ["West", "East"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Green-C",
               long_name: "Green Line C",
               route_type: 0,
               direction_names: ["West", "East"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Green-D",
               long_name: "Green Line D",
               route_type: 0,
               direction_names: ["West", "East"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Green-E",
               long_name: "Green Line E",
               route_type: 0,
               direction_names: ["West", "East"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Mattapan",
               long_name: "Mattapan Trolley",
               route_type: 0,
               direction_names: ["Outbound", "Inbound"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Orange",
               long_name: "Orange Line",
               route_type: 1,
               direction_names: ["South", "North"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Red",
               long_name: "Red Line",
               route_type: 1,
               direction_names: ["South", "North"],
               stop_list: [{"Braintree", "place-brntn", _, _} | _]
             },
             %Route{
               route_id: "Red",
               long_name: "Red Line",
               route_type: 1,
               direction_names: ["South", "North"],
               stop_list: [{"Ashmont", "place-asmnl", _, _} | _]
             }
           ] = Enum.sort_by(route_info, & &1.route_id)
  end

  test "get_subway_full_routes/0 returns subway routes with a single red line", %{pid: pid} do
    {:ok, route_info} = ServiceInfoCache.get_subway_full_routes(pid)

    assert [
             %Route{
               route_id: "Blue",
               long_name: "Blue Line",
               route_type: 1,
               direction_names: ["West", "East"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Green-B",
               long_name: "Green Line B",
               route_type: 0,
               direction_names: ["West", "East"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Green-C",
               long_name: "Green Line C",
               route_type: 0,
               direction_names: ["West", "East"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Green-D",
               long_name: "Green Line D",
               route_type: 0,
               direction_names: ["West", "East"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Green-E",
               long_name: "Green Line E",
               route_type: 0,
               direction_names: ["West", "East"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Mattapan",
               long_name: "Mattapan Trolley",
               route_type: 0,
               direction_names: ["Outbound", "Inbound"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Orange",
               long_name: "Orange Line",
               route_type: 1,
               direction_names: ["South", "North"],
               stop_list: [{_, _, _, _} | _]
             },
             %Route{
               route_id: "Red",
               long_name: "Red Line",
               route_type: 1,
               direction_names: ["South", "North"],
               stop_list: [{"Braintree", "place-brntn", _, _} | _]
             }
           ] = Enum.sort_by(route_info, & &1.route_id)
  end

  describe "get_bus_info/0" do
    test "returns bus headsign lists", %{pid: pid} do
      {:ok, [route | _]} = ServiceInfoCache.get_bus_info(pid)

      assert route == %AlertProcessor.Model.Route{
               direction_names: ["Outbound", "Inbound"],
               headsigns: %{
                 0 => ["Logan Airport", "Silver Line Way"],
                 1 => ["South Station"]
               },
               long_name: "Logan Airport Terminals - South Station",
               order: 0,
               route_id: "741",
               route_type: 3,
               short_name: "SL1",
               stop_list: [
                 {"World Trade Center", "place-wtcst", {42.34863, -71.04246}, 1},
                 {"Courthouse", "place-crtst", {42.35245, -71.04685}, 1},
                 {"South Station", "place-sstat", {42.352271, -71.055242}, 1}
               ],
               direction_destinations: ["Logan Airport Terminals", "South Station"]
             }
    end

    test "includes populated stop_list for Silver Line routes", %{pid: pid} do
      {:ok, routes} = ServiceInfoCache.get_bus_info(pid)
      silver_line_route_ids = ~w(741 742 743)

      for silver_line_route_id <- silver_line_route_ids do
        route = Enum.find(routes, &(&1.route_id == silver_line_route_id))
        assert length(route.stop_list) > 0
      end
    end
  end

  test "get_commuter_rail_info/0 returns commuter rail info", %{pid: pid} do
    {:ok, [route | _]} = ServiceInfoCache.get_commuter_rail_info(pid)

    assert route == %AlertProcessor.Model.Route{
             direction_destinations: ["Fairmount", "South Station"],
             direction_names: ["Outbound", "Inbound"],
             headsigns: nil,
             long_name: "Fairmount Line",
             order: 0,
             route_id: "CR-Fairmount",
             route_type: 2,
             short_name: "",
             stop_list: [
               {"Readville", "place-DB-0095", {42.238405, -71.133246}, 1},
               {"Fairmount", "place-DB-2205", {42.253638, -71.11927}, 1},
               {"Blue Hill Avenue", "place-DB-2222", {42.271466, -71.095782}, 1},
               {"Morton Street", "place-DB-2230", {42.280994, -71.085475}, 1},
               {"Talbot Avenue", "place-DB-2240", {42.292246, -71.07814}, 1},
               {"Four Corners/Geneva", "place-DB-2249", {42.305037, -71.076833}, 1},
               {"Uphams Corner", "place-DB-2258", {42.319125, -71.068627}, 1},
               {"Newmarket", "place-DB-2265", {42.327415, -71.065674}, 1},
               {"South Station", "place-sstat", {42.352271, -71.055242}, 1}
             ]
           }
  end

  test "get_ferry_info/0 returns ferry info", %{pid: pid} do
    {:ok, route_info} = ServiceInfoCache.get_ferry_info(pid)

    assert [
             %AlertProcessor.Model.Route{
               direction_names: ["Outbound", "Inbound"],
               direction_destinations: ["Charlestown", "Long Wharf"],
               headsigns: nil,
               long_name: "Charlestown Ferry",
               order: 0,
               route_id: "Boat-F4",
               route_type: 4,
               short_name: "",
               stop_list: [
                 {"Charlestown Navy Yard", "Boat-Charlestown", {42.372756, -71.052528}, 1},
                 {"Long Wharf (South)", "Boat-Long-South", {42.359448, -71.050498}, 1}
               ]
             },
             %AlertProcessor.Model.Route{
               direction_names: ["Outbound", "Inbound"],
               direction_destinations: ["Hingham or Hull", "Long Wharf or Rowes Wharf"],
               headsigns: nil,
               long_name: "Hingham/Hull Ferry",
               order: 1,
               route_id: "Boat-F1",
               route_type: 4,
               short_name: "",
               stop_list: [
                 {"Hingham", "Boat-Hingham", {42.253956, -70.919844}, 1},
                 {"Rowes Wharf", "Boat-Rowes", {42.355721, -71.049897}, 1},
                 {"Hull", "Boat-Hull", {42.303251, -70.920215}, 1},
                 {"Logan Airport Ferry Terminal", "Boat-Logan", {42.359789, -71.02734}, 1},
                 {"Long Wharf (North)", "Boat-Long", {42.360795, -71.049976}, 1}
               ]
             },
             %AlertProcessor.Model.Route{
               direction_names: ["Outbound", "Inbound"],
               direction_destinations: ["Lewis Mall Wharf", "Long Wharf"],
               headsigns: nil,
               long_name: "East Boston Ferry",
               order: 2,
               route_id: "Boat-EastBoston",
               route_type: 4,
               short_name: "",
               stop_list: [
                 {"Lewis Mall Wharf", "Boat-Lewis", {42.365867, -71.041958}, 1},
                 {"Long Wharf (North)", "Boat-Long", {42.360795, -71.049976}, 1}
               ]
             },
             %AlertProcessor.Model.Route{
               direction_names: ["Outbound", "Inbound"],
               direction_destinations: ["Blossom Street Pier", "Long Wharf"],
               headsigns: nil,
               long_name: "Lynn Ferry",
               order: 3,
               route_id: "Boat-Lynn",
               route_type: 4,
               short_name: "",
               stop_list: [
                 {"Blossom Street Pier", "Boat-Blossom", {42.45481, -70.94802}, 1},
                 {"Long Wharf (North)", "Boat-Long", {42.360795, -71.049976}, 1}
               ]
             },
             %AlertProcessor.Model.Route{
               direction_names: ["Outbound", "Inbound"],
               direction_destinations: ["Winthrop", "Central Wharf"],
               headsigns: nil,
               long_name: "Winthrop/Quincy Ferry",
               order: 4,
               route_id: "Boat-F6",
               route_type: 4,
               short_name: "",
               stop_list: []
             }
           ] = route_info
  end

  test "get_stop returns the correct stop", %{pid: pid} do
    assert {:ok, {"Davis", "place-davis", {42.39674, -71.121815}, 1}} ==
             ServiceInfoCache.get_stop(pid, "place-davis")

    assert {:ok, nil} == ServiceInfoCache.get_stop(pid, "place-doesnt-exist")
  end

  test "get_direction_name :subway returns the correct direction name", %{pid: pid} do
    assert {:ok, "West"} == ServiceInfoCache.get_direction_name(pid, "Blue", 0)
    assert {:ok, "North"} == ServiceInfoCache.get_direction_name(pid, "Red", 1)
    assert {:ok, "South"} == ServiceInfoCache.get_direction_name(pid, "Orange", 0)
    assert {:ok, "East"} == ServiceInfoCache.get_direction_name(pid, "Green-B", 1)
    assert {:ok, "West"} == ServiceInfoCache.get_direction_name(pid, "Green-C", 0)
    assert {:ok, "East"} == ServiceInfoCache.get_direction_name(pid, "Green-D", 1)
    assert {:ok, "West"} == ServiceInfoCache.get_direction_name(pid, "Green-E", 0)
    assert :error == ServiceInfoCache.get_direction_name(pid, "garbage", 1)
  end

  test "get_headsign :subway returns the correct headsigns", %{pid: pid} do
    assert {:ok, "Ashmont"} == ServiceInfoCache.get_headsign(pid, "place-davis", "place-asmnl", 0)

    assert {:ok, "Braintree"} ==
             ServiceInfoCache.get_headsign(pid, "place-davis", "place-brntn", 0)

    assert {:ok, "Alewife"} == ServiceInfoCache.get_headsign(pid, "place-asmnl", "place-davis", 1)
    assert {:ok, "Alewife"} == ServiceInfoCache.get_headsign(pid, "place-brntn", "place-davis", 1)

    assert {:ok, "Braintree or Ashmont"} ==
             ServiceInfoCache.get_headsign(pid, "place-davis", "place-pktrm", 0)

    assert {:ok, "Alewife"} == ServiceInfoCache.get_headsign(pid, "place-pktrm", "place-davis", 1)
    assert {:ok, "C"} == ServiceInfoCache.get_headsign(pid, "place-gover", "place-clmnl", 0)
    assert {:ok, "C"} == ServiceInfoCache.get_headsign(pid, "place-clmnl", "place-gover", 1)
    assert {:ok, "D or E"} == ServiceInfoCache.get_headsign(pid, "place-gover", "place-north", 0)
    assert :error == ServiceInfoCache.get_headsign(pid, "garbage", "more garbage", 1)
  end

  test "get_route returns the correct Route", %{pid: pid} do
    assert {:ok, %Route{long_name: "Red Line", short_name: ""}} =
             ServiceInfoCache.get_route(pid, "Red")

    assert {:ok, %Route{long_name: "Green Line B", short_name: "B"}} =
             ServiceInfoCache.get_route(pid, "Green-B")

    assert {:ok, %Route{long_name: "Mattapan Trolley", short_name: ""}} =
             ServiceInfoCache.get_route(pid, "Mattapan")

    assert {:ok, %Route{long_name: "Orange Line", short_name: ""}} =
             ServiceInfoCache.get_route(pid, "Orange")

    assert {:ok, %Route{route_id: "Green"}} = ServiceInfoCache.get_route(pid, "Green")
  end

  test "get_route orders stops correctly for all Green branches combined", %{pid: pid} do
    assert {:ok, %Route{route_id: "Green", stop_list: stop_list}} =
             ServiceInfoCache.get_route(pid, "Green")

    northeastern_index =
      Enum.find_index(stop_list, fn {_name, id, _lat_lon, _wheelchair_boarding} ->
        id == "place-nuniv"
      end)

    park_index =
      Enum.find_index(stop_list, fn {_name, id, _lat_lon, _wheelchair_boarding} ->
        id == "place-pktrm"
      end)

    assert northeastern_index < park_index
  end

  test "get_route/2 finds correct red line shape for given stops", %{pid: pid} do
    # Refer to
    # https://cdn.mbta.com/sites/default/files/maps/2018-04-map-rapid-transit-key-bus-v31a.pdf
    # for details about the Red line's shapes/branches.
    filter1 = %{route_id: "Red", stop_ids: ["place-alfcl", "place-qamnl"]}
    {:ok, %Route{stop_list: stop_list1}} = ServiceInfoCache.get_route(pid, filter1)
    assert {"Braintree", _, _, _} = List.first(stop_list1)

    filter2 = %{route_id: "Red", stop_ids: ["place-alfcl", "place-smmnl"]}
    {:ok, %Route{stop_list: stop_list2}} = ServiceInfoCache.get_route(pid, filter2)
    assert {"Ashmont", _, _, _} = List.first(stop_list2)
  end

  test "get_route/2 ignores stops with non-Red route_id", %{pid: pid} do
    filter = %{route_id: "Orange", stop_ids: ["non-existent-stop-id"]}

    assert {:ok, %Route{long_name: "Orange Line", short_name: ""}} =
             ServiceInfoCache.get_route(pid, filter)
  end

  test "get_route/2 returns an error with a nonexistent route ID", %{pid: pid} do
    assert {:error, :not_found} = ServiceInfoCache.get_route(pid, "no-such-route-id")
  end

  test "get_route/2 returns an error with an invalid argument", %{pid: pid} do
    assert {:error, :invalid_argument} = ServiceInfoCache.get_route(pid, nil)
  end

  test "get_routes/1 returns all the routes", %{pid: pid} do
    {:ok, routes} = ServiceInfoCache.get_routes(pid)
    assert Enum.all?(routes, fn route -> route.__struct__ == Route end)
  end

  test "get_parent_stop_id returns the correct parent stop id", %{pid: pid} do
    assert {:ok, "place-gover"} = ServiceInfoCache.get_parent_stop_id(pid, "70039")
    assert {:ok, "place-fenwy"} = ServiceInfoCache.get_parent_stop_id(pid, "70186")
    assert {:ok, "place-ogmnl"} = ServiceInfoCache.get_parent_stop_id(pid, "70036")
    assert {:ok, "place-davis"} = ServiceInfoCache.get_parent_stop_id(pid, "70063")
    assert {:ok, "place-north"} = ServiceInfoCache.get_parent_stop_id(pid, "BNT-0000")
    assert {:ok, "place-portr"} = ServiceInfoCache.get_parent_stop_id(pid, "FR-0034")
    assert {:ok, nil} = ServiceInfoCache.get_parent_stop_id(pid, "garbage")
  end

  @tag skip: "fails when the current day is not a weekday"
  test "get_generalized_trip_id", %{pid: pid} do
    assert {:ok, "Boat-F4-Boat-Charlestown-11:45:00-weekday-1"} ==
             ServiceInfoCache.get_generalized_trip_id(pid, "Boat-F4-1145-Charlestown-Weekday")

    assert {:ok, nil} = ServiceInfoCache.get_generalized_trip_id(pid, "garbage")
  end

  @tag skip: "fails every time commuter rail trips change"
  test "get_trip_name", %{pid: pid} do
    assert {:ok, "1801"} = ServiceInfoCache.get_trip_name(pid, "CR-Weekday-Winter-21-1801")
  end

  test "get_facility_map", %{pid: pid} do
    assert {:ok,
            %{
              "929" => "ELEVATOR",
              "909" => "ELEVATOR",
              "516" => "ESCALATOR",
              "408" => "ESCALATOR",
              "311" => "ESCALATOR",
              "304" => "ESCALATOR",
              "320" => "ESCALATOR",
              "923" => "ELEVATOR",
              "945" => "ELEVATOR",
              "830" => "ELEVATOR",
              "936" => "ELEVATOR",
              "986" => "ELEVATOR",
              "954" => "ELEVATOR",
              "145" => "ESCALATOR",
              "940" => "ELEVATOR",
              "362" => "ESCALATOR",
              "386" => "ESCALATOR",
              "137" => "ESCALATOR",
              "143" => "ESCALATOR",
              "380" => "ESCALATOR",
              "904" => "ELEVATOR",
              "113" => "ESCALATOR",
              "928" => "ELEVATOR",
              "983" => "ELEVATOR",
              "138" => "ESCALATOR",
              "442" => "ESCALATOR",
              "378" => "ESCALATOR",
              "899" => "ELEVATOR",
              "901" => "ELEVATOR",
              "148" => "ESCALATOR",
              "307" => "ESCALATOR",
              "428" => "ESCALATOR",
              "962" => "ELEVATOR",
              "708" => "ELEVATOR",
              "416" => "ESCALATOR",
              "948" => "ELEVATOR",
              "354" => "ESCALATOR",
              "711" => "ELEVATOR",
              "910" => "ELEVATOR",
              "876" => "ELEVATOR",
              "332" => "ESCALATOR",
              "149" => "ESCALATOR",
              "407" => "ESCALATOR",
              "980" => "ELEVATOR",
              "309" => "ESCALATOR",
              "815" => "ELEVATOR",
              "800" => "ELEVATOR",
              "963" => "ELEVATOR"
            }} = ServiceInfoCache.get_facility_map(pid)
  end

  test "get_stops_with_icons", %{pid: pid} do
    {:ok, stops_with_icons} = ServiceInfoCache.get_stops_with_icons(pid)
    assert stops_with_icons["2050"] == [modes: MapSet.new([:bus]), accessible: false]

    assert stops_with_icons["place-north"] == [
             modes: MapSet.new([:cr, :"green-d", :"green-e", :orange]),
             accessible: true
           ]

    assert stops_with_icons["place-NHRML-0254"] == [modes: MapSet.new([:cr]), accessible: true]
    assert stops_with_icons["Boat-Hingham"] == [modes: MapSet.new([:ferry]), accessible: true]
  end
end
