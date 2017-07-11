defmodule AlertProcessor.ServiceInfoCacheTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{Model.Route, ServiceInfoCache}

  test "get_subway_info/0 returns subway branch lists" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_subway])
      {:ok, route_info} = ServiceInfoCache.get_subway_info(pid)
      assert [
        %Route{route_id: "Blue", long_name: "Blue Line", route_type: 1, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _} | _]},
        %Route{route_id: "Green-B", long_name: "Green Line B", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Green-C", long_name: "Green Line C", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Green-D", long_name: "Green Line D", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Green-E", long_name: "Green Line E", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Mattapan", long_name: "Mattapan Trolley", route_type: 0, direction_names: ["Outbound", "Inbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Orange", long_name: "Orange Line", route_type: 1, direction_names: ["Southbound", "Northbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Red", long_name: "Red Line", route_type: 1, direction_names: ["Southbound", "Northbound"], stop_list: [{"Ashmont", "place-asmnl"}| _]},
        %Route{route_id: "Red", long_name: "Red Line", route_type: 1, direction_names: ["Southbound", "Northbound"], stop_list: [{"Braintree", "place-brntn"}| _]}
      ] = Enum.sort_by(route_info, &(&1.route_id))
    end
  end

  test "get_subway_full_routes/0 returns subway routes with a single red line" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_subway])
      {:ok, route_info} = ServiceInfoCache.get_subway_full_routes(pid)
      assert [
        %Route{route_id: "Blue", long_name: "Blue Line", route_type: 1, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _} | _]},
        %Route{route_id: "Green-B", long_name: "Green Line B", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Green-C", long_name: "Green Line C", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Green-D", long_name: "Green Line D", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Green-E", long_name: "Green Line E", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Mattapan", long_name: "Mattapan Trolley", route_type: 0, direction_names: ["Outbound", "Inbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Orange", long_name: "Orange Line", route_type: 1, direction_names: ["Southbound", "Northbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Red", long_name: "Red Line", route_type: 1, direction_names: ["Southbound", "Northbound"], stop_list: [{"Braintree", "place-brntn"}| _]}
      ] = Enum.sort_by(route_info, &(&1.route_id))
    end
  end

  test "get_bus_info/0 returns bus headsign lists" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_bus])
      {:ok, route_info} = ServiceInfoCache.get_bus_info(pid)
      assert [
        %Route{
          route_id: "57",
          long_name: "57",
          route_type: 3,
          direction_names: ["Outbound", "Inbound"],
          headsigns: %{
            0 => ["Watertown Yard", "Watertown via Kenmore"],
            1 => ["Kenmore", "Haymarket via Kenmore", "Union Square, Allston"]
          }
        },
        %Route{
          route_id: "741",
          long_name: "Silver Line SL1",
          route_type: 3,
          direction_names: ["Outbound", "Inbound"],
          headsigns: %{
            0 => ["Logan Airport", "Silver Line Way"],
            1 => ["South Station"]
          }
        },
        %Route{
          route_id: "87",
          long_name: "87",
          route_type: 3,
          direction_names: ["Outbound", "Inbound"],
          headsigns: %{
            0 => ["Arlington Center", "Clarendon Hill"],
            1 => ["Lechmere"]
          }
        }
      ] = Enum.sort_by(route_info, &(&1.route_id))
    end
  end

  test "get_commuter_rail_info/0 returns commuter rail info" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_commuter_rail])
      {:ok, route_info} = ServiceInfoCache.get_commuter_rail_info(pid)
      assert [
        %Route{route_id: "CR-Fairmount", long_name: "Fairmount Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Readville", "Readville"} | _]},
        %Route{route_id: "CR-Fitchburg", long_name: "Fitchburg Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Wachusett", "Wachusett"} | _]},
        %Route{route_id: "CR-Worcester", long_name: "Framingham/Worcester Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Worcester", "Worcester"} | _]},
        %Route{route_id: "CR-Franklin", long_name: "Franklin Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Forge Park/495", "Forge Park / 495"} | _]},
        %Route{route_id: "CR-Greenbush", long_name: "Greenbush Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Greenbush", "Greenbush"} | _]},
        %Route{route_id: "CR-Haverhill", long_name: "Haverhill Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Haverhill", "Haverhill"} | _]},
        %Route{route_id: "CR-Kingston", long_name: "Kingston/Plymouth Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Plymouth", "Plymouth"} | _]},
        %Route{route_id: "CR-Lowell", long_name: "Lowell Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Lowell", "Lowell"} | _]},
        %Route{route_id: "CR-Middleborough", long_name: "Middleborough/Lakeville Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Middleborough/Lakeville",
                "Middleborough/ Lakeville"} | _]},
        %Route{route_id: "CR-Needham", long_name: "Needham Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Needham Heights", "Needham Heights"} | _]},
        %Route{route_id: "CR-Newburyport", long_name: "Newburyport/Rockport Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Rockport", "Rockport"} | _]},
        %Route{route_id: "CR-Providence", long_name: "Providence/Stoughton Line", route_type: 2, direction_names: ["Outbound", "Inbound"], stop_list: [{"Wickford Junction", "Wickford Junction"} | _]}
      ] = route_info
    end
  end

  test "get_ferry_info/0 returns ferry info" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_ferry])
      {:ok, route_info} = ServiceInfoCache.get_ferry_info(pid)
      assert [
        %Route{route_id: "Boat-F4", long_name: "Charlestown Ferry", route_type: 4, direction_names: ["Outbound", "Inbound"], stop_list: [{"Charlestown Navy Yard", "Boat-Charlestown"} | _]},
        %Route{route_id: "Boat-F1", long_name: "Hingham Ferry", route_type: 4, direction_names: ["Outbound", "Inbound"], stop_list: [{"Hewitt's Cove, Hingham", "Boat-Hingham"} | _]},
        %Route{route_id: "Boat-F3", long_name: "Hull Ferry", route_type: 4, direction_names: ["Outbound", "Inbound"], stop_list: [{"Pemberton Point, Hull", "Boat-Hull"} | _]}
      ] = route_info
    end
  end

  test "get_stop returns the correct stop" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_stop])
      assert {:ok, {"Davis", "place-davis"}} == ServiceInfoCache.get_stop(pid, "place-davis")
      assert {:ok, nil} == ServiceInfoCache.get_stop(pid, "place-doesnt-exist")
    end
  end

  test "get_stop_by_name returns the correct stop" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_stop])
      assert {:ok, {"Davis", "place-davis"}} == ServiceInfoCache.get_stop_by_name(pid, "Davis")
      assert {:ok, nil} == ServiceInfoCache.get_stop(pid, "Place doesn't exist")
    end
  end

  test "get_direction_name :subway returns the correct direction name" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_direction_name])
      assert {:ok, "Westbound"} == ServiceInfoCache.get_direction_name(pid, "Blue", 0)
      assert {:ok, "Northbound"} == ServiceInfoCache.get_direction_name(pid, "Red", 1)
      assert {:ok, "Southbound"} == ServiceInfoCache.get_direction_name(pid, "Orange", 0)
      assert {:ok, "Eastbound"} == ServiceInfoCache.get_direction_name(pid, "Green-B", 1)
      assert {:ok, "Westbound"} == ServiceInfoCache.get_direction_name(pid, "Green-C", 0)
      assert {:ok, "Eastbound"} == ServiceInfoCache.get_direction_name(pid, "Green-D", 1)
      assert {:ok, "Westbound"} == ServiceInfoCache.get_direction_name(pid, "Green-E", 0)
      assert :error == ServiceInfoCache.get_direction_name(pid, "garbage", 1)
    end
  end

  test "get_headsign :subway returns the correct headsigns" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_headsigns])
      assert {:ok, "Ashmont"} == ServiceInfoCache.get_headsign(pid, "Davis", "Ashmont", 0)
      assert {:ok, "Braintree"} == ServiceInfoCache.get_headsign(pid, "Davis", "Braintree", 0)
      assert {:ok, "Alewife"} == ServiceInfoCache.get_headsign(pid, "Ashmont", "Davis", 1)
      assert {:ok, "Alewife"} == ServiceInfoCache.get_headsign(pid, "Braintree", "Davis", 1)
      assert {:ok, "Ashmont or Braintree"} == ServiceInfoCache.get_headsign(pid, "Davis", "Park Street", 0)
      assert {:ok, "Alewife"} == ServiceInfoCache.get_headsign(pid, "Park Street", "Davis", 1)
      assert {:ok, "C"} == ServiceInfoCache.get_headsign(pid, "North Station", "Cleveland Circle", 0)
      assert {:ok, "C"} == ServiceInfoCache.get_headsign(pid, "Cleveland Circle", "North Station", 1)
      assert {:ok, "B, C, D, or E"} == ServiceInfoCache.get_headsign(pid, "Government Center", "Haymarket", 0)
      assert :error == ServiceInfoCache.get_headsign(pid, "garbage", "more garbage", 1)
    end
  end

  test "get_route returns the correct Route" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_get_route])
      assert {:ok, %Route{long_name: "Red Line"}} = ServiceInfoCache.get_route(pid, "Red")
      assert {:ok, %Route{long_name: "Green Line B"}} = ServiceInfoCache.get_route(pid, "Green-B")
      assert {:ok, %Route{long_name: "Mattapan Trolley"}} = ServiceInfoCache.get_route(pid, "Mattapan")
      assert {:ok, %Route{long_name: "Orange Line"}} = ServiceInfoCache.get_route(pid, "Orange")
    end
  end

  test "get_parent_stop_id returns the correct parent stop id" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_get_parent_stop_id])
      assert {:ok, "place-gover"} = ServiceInfoCache.get_parent_stop_id(pid, "70039")
      assert {:ok, "place-fenwy"} = ServiceInfoCache.get_parent_stop_id(pid, "70186")
      assert {:ok, "place-ogmnl"} = ServiceInfoCache.get_parent_stop_id(pid, "70036")
      assert {:ok, "place-davis"} = ServiceInfoCache.get_parent_stop_id(pid, "70063")
      assert {:ok, nil} = ServiceInfoCache.get_parent_stop_id(pid, "garbage")
    end
  end
end
