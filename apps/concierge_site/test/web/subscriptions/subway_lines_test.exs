defmodule ConciergeSite.Subscriptions.SubwayLinesTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.SubwayLines

  describe "station_select_list_options" do
    test "changes a map of routes into a keyword list" do
      routes = [
        %AlertProcessor.Model.Route{direction_names: [],long_name: "Green Line D", route_type: 0, stop_list: []},
        %AlertProcessor.Model.Route{direction_names: [],long_name: "Red Line", route_type: 0, stop_list: []},
        %AlertProcessor.Model.Route{direction_names: [],long_name: "Blue Line", route_type: 0, stop_list: []}
      ]

      select_options = SubwayLines.station_list_select_options(routes)

      assert select_options == [{"Green Line D", []}, {"Red Line", []}, {"Blue Line", []}]
    end
  end
end
