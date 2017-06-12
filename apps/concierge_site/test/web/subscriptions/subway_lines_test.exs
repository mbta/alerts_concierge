defmodule ConciergeSite.Subscriptions.SubwayLinesTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.SubwayLines

  describe "station_select_list_options" do
    test "changes a map of routes into a keyword list" do
      routes = [
<<<<<<< 41fef6e539de13df2bf7766a4e5b566084d0e377
        %AlertProcessor.Model.Route{direction_names: [], long_name: "Green Line D", route_type: 0, stop_list: []},
        %AlertProcessor.Model.Route{direction_names: [], long_name: "Red Line", route_type: 0, stop_list: []},
        %AlertProcessor.Model.Route{direction_names: [], long_name: "Blue Line", route_type: 0, stop_list: []}
=======
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
>>>>>>> Return Braintree and Ashmont Red Line names for select options
      ]

      select_options = SubwayLines.station_list_select_options(routes)

      assert select_options == [
        {"Green Line D", [{"Riverside", "place-river"}]},
        {"Orange Line", [{"Forest Hills", "place-forhl"}]},
        {"Blue Line", [{"Bowdoin", "place-bomnl"}]}
      ]
    end

    test "names the Red Line Ashmont and Braintree branches" do
      routes = [
        %AlertProcessor.Model.Route{
          direction_names: [],
          long_name: "Red Line",
          route_type: 0,
          stop_list: [
            {"Ashmont", "place-asmnl"},
            {"Shawmut", "place-smmnl"}
          ]
        },
        %AlertProcessor.Model.Route{
          direction_names: [],
          long_name: "Red Line",
          route_type: 0,
          stop_list: [
            {"Braintree", "place-brntn"},
            {"Quincy Adams", "place-qamnl"}
          ]
        },
        %AlertProcessor.Model.Route{
          direction_names: [],
          long_name: "Orange Line",
          route_type: 0,
          stop_list: [{"Forest Hills", "place-forhl"}
          ]
        }
      ]

      select_options = SubwayLines.station_list_select_options(routes)

      assert select_options == [
        {"Red Line Ashmont", [{"Ashmont", "place-asmnl"}, {"Shawmut", "place-smmnl"}]},
        {"Red Line Braintree", [{"Braintree", "place-brntn"}, {"Quincy Adams", "place-qamnl"}]},
        {"Orange Line", [{"Forest Hills", "place-forhl"}]}
      ]
    end
  end
end
