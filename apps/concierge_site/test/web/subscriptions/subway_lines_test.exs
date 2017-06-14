defmodule ConciergeSite.Subscriptions.SubwayLinesTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.SubwayLines

  describe "station_select_list_options" do
    test "changes a map of routes into a keyword list" do
      routes = [
        %AlertProcessor.Model.Route{
          direction_names: [],
          long_name: "Red Line",
          route_type: 0,
          stop_list: [{"Braintree", "place-river"}]
        },
        %AlertProcessor.Model.Route{
          direction_names: [],
          long_name: "Green Line D",
          route_type: 0,
          stop_list: [{"Riverside", "place-river"}]
        },
        %AlertProcessor.Model.Route{
          direction_names: [],
          long_name: "Orange Line",
          route_type: 0,
          stop_list: [{"Forest Hills", "place-forhl"}]
        },
        %AlertProcessor.Model.Route{
          direction_names: [],
          long_name: "Blue Line",
          route_type: 0,
          stop_list: [{"Bowdoin", "place-bomnl"}]
        }
      ]

      select_options = SubwayLines.station_list_select_options(routes)

      assert select_options == [
        {"Red Line", [{"Braintree", "place-river"}]},
        {"Green Line D", [{"Riverside", "place-river"}]},
        {"Orange Line", [{"Forest Hills", "place-forhl"}]},
        {"Blue Line", [{"Bowdoin", "place-bomnl"}]}
      ]
    end
  end
end
