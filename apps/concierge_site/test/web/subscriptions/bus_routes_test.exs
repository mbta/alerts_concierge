defmodule ConciergeSite.Subscriptions.BusRoutesTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias ConciergeSite.Subscriptions.BusRoutes

  describe "station_select_list_options" do
    test "changes a map of routes into a keyword list" do
      routes = [
        %AlertProcessor.Model.Route{
          route_id: "57A",
          long_name: "57A",
          route_type: 3,
        }
      ]

      select_options = BusRoutes.route_list_select_options(routes)

      assert select_options == [
        "57A - Inbound": "Route 57A - Inbound",
        "57A - Outbound": "Route 57A - Outbound"
      ]
    end
  end
end
