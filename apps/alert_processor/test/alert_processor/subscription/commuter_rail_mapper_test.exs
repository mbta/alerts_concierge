defmodule AlertProcessor.Subscription.CommuterRailMapperTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.{Model.Trip, Subscription.CommuterRailMapper}

  @test_date Calendar.Date.from_ordinal!(2017, 168)

  describe "map_trip_options" do
    test "returns inbound results for origin destination" do
      use_cassette "north_to_anderson_woburn_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        trips = CommuterRailMapper.map_trip_options("place-north", "Anderson/ Woburn", :weekday, @test_date)
        assert [%Trip{trip_number: "301", departure_time: ~T[05:35:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[05:59:00]},
                %Trip{trip_number: "303", departure_time: ~T[06:15:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[06:34:00]},
                %Trip{trip_number: "305", departure_time: ~T[06:37:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[07:01:00]},
                %Trip{trip_number: "307", departure_time: ~T[07:21:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[07:45:00]},
                %Trip{trip_number: "391", departure_time: ~T[07:42:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[08:02:00]},
                %Trip{trip_number: "309", departure_time: ~T[08:16:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[08:40:00]},
                %Trip{trip_number: "311", departure_time: ~T[09:15:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[09:39:00]},
                %Trip{trip_number: "313", departure_time: ~T[10:15:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[10:39:00]},
                %Trip{trip_number: "315", departure_time: ~T[11:15:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[11:39:00]},
                %Trip{trip_number: "317", departure_time: ~T[12:15:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[12:39:00]},
                %Trip{trip_number: "319", departure_time: ~T[13:15:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[13:39:00]} | rest] = trips


        assert [%Trip{trip_number: "321", departure_time: ~T[14:15:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[14:39:00]},
                %Trip{trip_number: "323", departure_time: ~T[15:00:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[15:24:00]},
                %Trip{trip_number: "325", departure_time: ~T[15:40:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[16:05:00]},
                %Trip{trip_number: "327", departure_time: ~T[16:15:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[16:40:00]},
                %Trip{trip_number: "329", departure_time: ~T[16:45:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[17:10:00]},
                %Trip{trip_number: "331", departure_time: ~T[17:10:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[17:35:00]},
                %Trip{trip_number: "333", departure_time: ~T[17:35:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[17:54:00]},
                %Trip{trip_number: "335", departure_time: ~T[17:50:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[18:15:00]},
                %Trip{trip_number: "337", departure_time: ~T[18:30:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[18:55:00]},
                %Trip{trip_number: "221", departure_time: ~T[18:55:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[19:20:00]},
                %Trip{trip_number: "339", departure_time: ~T[19:25:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[19:49:00]},
                %Trip{trip_number: "341", departure_time: ~T[20:35:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[20:59:00]},
                %Trip{trip_number: "343", departure_time: ~T[21:45:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[22:09:00]},
                %Trip{trip_number: "345", departure_time: ~T[22:55:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[23:19:00]},
                %Trip{trip_number: "347", departure_time: ~T[00:15:00], direction_id: 0, origin: "place-north", destination: "Anderson/ Woburn", arrival_time: ~T[00:39:00]}] = rest
      end
    end

    test "returns outbound results for origin destination" do
      use_cassette "anderson_woburn_to_north_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        trips = CommuterRailMapper.map_trip_options("Anderson/ Woburn", "place-north", :weekday, @test_date)
        assert [%Trip{trip_number: "300", departure_time: ~T[05:56:00], direction_id: 1, origin: "Anderson/ Woburn", destination: "place-north", arrival_time: ~T[06:22:00]},
                %Trip{trip_number: "302", departure_time: ~T[06:36:00], direction_id: 1, origin: "Anderson/ Woburn", destination: "place-north", arrival_time: ~T[07:01:00]},
                %Trip{trip_number: "304", departure_time: ~T[07:01:00], direction_id: 1, origin: "Anderson/ Woburn", destination: "place-north", arrival_time: ~T[07:27:00]},
                %Trip{trip_number: "306", departure_time: ~T[07:19:00], direction_id: 1, origin: "Anderson/ Woburn", destination: "place-north", arrival_time: ~T[07:47:00]},
                %Trip{trip_number: "308", departure_time: ~T[07:41:00], direction_id: 1, origin: "Anderson/ Woburn", destination: "place-north", arrival_time: ~T[08:06:00]},
                %Trip{trip_number: "310", departure_time: ~T[08:01:00], direction_id: 1, origin: "Anderson/ Woburn", destination: "place-north", arrival_time: ~T[08:21:00]},
                %Trip{trip_number: "392", departure_time: ~T[08:21:00], direction_id: 1, origin: "Anderson/ Woburn", destination: "place-north", arrival_time: ~T[08:47:00]},
                %Trip{trip_number: "312", departure_time: ~T[08:41:00], direction_id: 1, origin: "Anderson/ Woburn", destination: "place-north", arrival_time: ~T[09:06:00]},
                %Trip{trip_number: "314", departure_time: ~T[09:06:00], direction_id: 1, origin: "Anderson/ Woburn", destination: "place-north", arrival_time: ~T[09:31:00]} | _t] = trips
      end
    end

    test "returns error for invalid origin destination combo" do
      assert :error = CommuterRailMapper.map_trip_options("place-north", "Providence", :weekday, @test_date)
    end

    test "returns saturday results" do
      use_cassette "waltham_to_porter_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        trips = CommuterRailMapper.map_trip_options("Waltham", "place-portr", :saturday, @test_date)
        assert [%Trip{trip_number: "1400", departure_time: ~T[07:38:00], direction_id: 1, origin: "Waltham", destination: "place-portr", arrival_time: ~T[07:50:00]},
                %Trip{trip_number: "1402", departure_time: ~T[09:53:00], direction_id: 1, origin: "Waltham", destination: "place-portr", arrival_time: ~T[10:05:00]},
                %Trip{trip_number: "1404", departure_time: ~T[11:58:00], direction_id: 1, origin: "Waltham", destination: "place-portr", arrival_time: ~T[12:10:00]},
                %Trip{trip_number: "1406", departure_time: ~T[14:23:00], direction_id: 1, origin: "Waltham", destination: "place-portr", arrival_time: ~T[14:35:00]},
                %Trip{trip_number: "1408", departure_time: ~T[16:48:00], direction_id: 1, origin: "Waltham", destination: "place-portr", arrival_time: ~T[17:00:00]},
                %Trip{trip_number: "1410", departure_time: ~T[19:18:00], direction_id: 1, origin: "Waltham", destination: "place-portr", arrival_time: ~T[19:30:00]},
                %Trip{trip_number: "1412", departure_time: ~T[22:53:00], direction_id: 1, origin: "Waltham", destination: "place-portr", arrival_time: ~T[23:05:00]} | _t] = trips
      end
    end

    test "returns sunday results" do
      use_cassette "porter_to_waltham_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        trips = CommuterRailMapper.map_trip_options("place-portr", "Waltham", :sunday, @test_date)
        assert [%Trip{trip_number: "2401", departure_time: ~T[08:45:00], direction_id: 0, origin: "place-portr", destination: "Waltham", arrival_time: ~T[08:57:00]},
                %Trip{trip_number: "2403", departure_time: ~T[10:55:00], direction_id: 0, origin: "place-portr", destination: "Waltham", arrival_time: ~T[11:07:00]},
                %Trip{trip_number: "2405", departure_time: ~T[13:20:00], direction_id: 0, origin: "place-portr", destination: "Waltham", arrival_time: ~T[13:32:00]},
                %Trip{trip_number: "2407", departure_time: ~T[15:40:00], direction_id: 0, origin: "place-portr", destination: "Waltham", arrival_time: ~T[15:52:00]},
                %Trip{trip_number: "2409", departure_time: ~T[17:55:00], direction_id: 0, origin: "place-portr", destination: "Waltham", arrival_time: ~T[18:07:00]},
                %Trip{trip_number: "2411", departure_time: ~T[20:05:00], direction_id: 0, origin: "place-portr", destination: "Waltham", arrival_time: ~T[20:17:00]},
                %Trip{trip_number: "2413", departure_time: ~T[23:40:00], direction_id: 0, origin: "place-portr", destination: "Waltham", arrival_time: ~T[23:52:00]}] = trips
      end
    end
  end
end
