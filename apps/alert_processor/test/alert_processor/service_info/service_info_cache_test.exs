defmodule AlertProcessor.ServiceInfoCacheTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{Model.Route, ServiceInfoCache}

  test "get_subway_info/0 returns subway branch lists" do
    use_cassette "service_info", custom: true, clear_mock: true do
      ServiceInfoCache.start_link()
      {:ok, route_info} = ServiceInfoCache.get_subway_info()
      assert [
        %Route{route_id: "Blue", route_type: 1, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _} | _]},
        %Route{route_id: "Green-B", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Green-C", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Green-D", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Green-E", route_type: 0, direction_names: ["Westbound", "Eastbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Mattapan", route_type: 0, direction_names: ["Outbound", "Inbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Orange", route_type: 1, direction_names: ["Southbound", "Northbound"], stop_list: [{_, _}| _]},
        %Route{route_id: "Red", route_type: 1, direction_names: ["Southbound", "Northbound"], stop_list: [{_, _}| _]}
      ] = Enum.sort_by(route_info, &(&1.route_id))
    end
  end
end
