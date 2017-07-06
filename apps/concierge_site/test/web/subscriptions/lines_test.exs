defmodule ConciergeSite.Subscriptions.LinesTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias ConciergeSite.Subscriptions.Lines

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

      select_options = Lines.station_list_select_options(routes)

      assert select_options == [
        {"Red Line", [{"Braintree", "place-river"}]},
        {"Green Line D", [{"Riverside", "place-river"}]},
        {"Orange Line", [{"Forest Hills", "place-forhl"}]},
        {"Blue Line", [{"Bowdoin", "place-bomnl"}]}
      ]
    end
  end

  describe "subway_station_name_from_id" do
    test "it returns the station name associated with a given id" do
      use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
        params = %{"origin" => "place-brntn", "destination" => "place-qamnl"}
        station_names = Lines.subway_station_names_from_ids(params)
        assert %{"origin" => "Braintree", "destination" => "Quincy Adams"} == station_names
      end
    end
  end

  describe "station_ids_from_names/1" do
    test "given a list of commuter rail and subway names, returns a list of station ids" do
      use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
        subway_stations = ["Quincy Center", "JFK/Umass"]
        commuter_stations = ["Ruggles", "Sharon"]
        station_names = subway_stations ++ commuter_stations
        station_ids = ["place-qnctr", "place-jfk", "place-rugg", "Sharon"]
        assert  Lines.station_ids_from_names(station_names) == station_ids
      end
    end
  end
end
