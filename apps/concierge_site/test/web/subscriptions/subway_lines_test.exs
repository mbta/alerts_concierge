defmodule ConciergeSite.Subscriptions.SubwayLinesTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.SubwayLines

  describe "station_select_list_options" do
    test "changes a map of routes into a keyword list" do
      routes = [
        %AlertProcessor.Model.Route{direction_names: [],route_id: "Green", route_type: 0, stop_list: []},
        %AlertProcessor.Model.Route{direction_names: [],route_id: "Red", route_type: 0, stop_list: []},
        %AlertProcessor.Model.Route{direction_names: [],route_id: "Blue", route_type: 0, stop_list: []}
      ]

      select_options = SubwayLines.station_list_select_options(routes)

      assert select_options == [{"Green", []}, {"Red", []}, {"Blue", []}]
    end
  end
end
