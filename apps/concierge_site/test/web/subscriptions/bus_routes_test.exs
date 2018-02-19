defmodule ConciergeSite.Subscriptions.BusRoutesTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias ConciergeSite.Subscriptions.BusRoutes

  describe "station_select_list_options" do
    test "changes a map of routes into a keyword list" do
      routes = [
        %AlertProcessor.Model.Route{
          route_id: "57A",
          long_name: "57A Long Name",
          route_type: 3,
          headsigns: %{
            0 => ["Logan Airport", "Silver Line Way"],
            1 => ["South Station"]
          }
        }
      ]

      select_options = BusRoutes.route_list_select_options(routes)

      assert select_options == [{"Route 57A Long Name - South Station", "57A - 1"}, {"Route 57A Long Name - Logan Airport, Silver Line Way", "57A - 0"}]
    end

    test "uses inbound and outbound when there are no headsigns" do
      routes = [
        %AlertProcessor.Model.Route{
          route_id: "57A",
          long_name: "57A Long Name",
          route_type: 3,
        }
      ]

      select_options = BusRoutes.route_list_select_options(routes)

      assert select_options == [{"Route 57A Long Name - Inbound", "57A - 1"}, {"Route 57A Long Name - Outbound", "57A - 0"}]
    end
  end
end
