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

  test "get_bus_info/0 returns bus headsign lists" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_bus])
      assert {:ok, %{
        "57" => %{
          0 => ["Watertown Yard", "Watertown via Kenmore"],
          1 => ["Kenmore", "Haymarket via Kenmore", "Union Square, Allston"]
        },
        "741" => %{
          0 => ["Logan Airport", "Silver Line Way"],
          1 => ["South Station"]
        },
        "87" => %{
          0 => ["Arlington Center", "Clarendon Hill"],
          1 => ["Lechmere"]
        }
      }} = ServiceInfoCache.get_bus_info(pid)
    end
  end

  test "get_stop returns the correct stop" do
    use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
      {:ok, pid} = ServiceInfoCache.start_link([name: :service_info_cache_test_stop])
      assert {:ok, {"Davis", "place-davis"}} == ServiceInfoCache.get_stop(pid, :subway, "place-davis")
      assert {:ok, nil} == ServiceInfoCache.get_stop(pid, :subway, "place-doesnt-exist")
    end
  end
end
