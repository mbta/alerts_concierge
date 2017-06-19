defmodule AlertProcessor.Subscription.CommuterRailMapperTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.Subscription.CommuterRailMapper

  @test_date Calendar.Date.from_ordinal!(2017, 168)

  describe "map_trip_options" do
    test "returns inbound results for origin destination" do
      use_cassette "north_to_anderson_woburn_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        trips = CommuterRailMapper.map_trip_options("place-north", "Anderson/ Woburn", :weekday, @test_date)
        assert [{"301", ~T[05:35:00], ["301", " ", "Outbound", " | Departs ", "North Station", " at ", "5:35am", ", arrives at ", "Anderson/Woburn", " at ", "5:59am"]},
                {"303", ~T[06:15:00], ["303", " ", "Outbound", " | Departs ", "North Station", " at ", "6:15am", ", arrives at ", "Anderson/Woburn", " at ", "6:34am"]},
                {"305", ~T[06:37:00], ["305", " ", "Outbound", " | Departs ", "North Station", " at ", "6:37am", ", arrives at ", "Anderson/Woburn", " at ", "7:01am"]},
                {"307", ~T[07:21:00], ["307", " ", "Outbound", " | Departs ", "North Station", " at ", "7:21am", ", arrives at ", "Anderson/Woburn", " at ", "7:45am"]},
                {"391", ~T[07:42:00], ["391", " ", "Outbound", " | Departs ", "North Station", " at ", "7:42am", ", arrives at ", "Anderson/Woburn", " at ", "8:02am"]},
                {"309", ~T[08:16:00], ["309", " ", "Outbound", " | Departs ", "North Station", " at ", "8:16am", ", arrives at ", "Anderson/Woburn", " at ", "8:40am"]},
                {"311", ~T[09:15:00], ["311", " ", "Outbound", " | Departs ", "North Station", " at ", "9:15am", ", arrives at ", "Anderson/Woburn", " at ", "9:39am"]},
                {"313", ~T[10:15:00], ["313", " ", "Outbound", " | Departs ", "North Station", " at ", "10:15am", ", arrives at ", "Anderson/Woburn", " at ", "10:39am"]},
                {"315", ~T[11:15:00], ["315", " ", "Outbound", " | Departs ", "North Station", " at ", "11:15am", ", arrives at ", "Anderson/Woburn", " at ", "11:39am"]},
                {"317", ~T[12:15:00], ["317", " ", "Outbound", " | Departs ", "North Station", " at ", "12:15pm", ", arrives at ", "Anderson/Woburn", " at ", "12:39pm"]},
                {"319", ~T[13:15:00], ["319", " ", "Outbound", " | Departs ", "North Station", " at ", "1:15pm", ", arrives at ", "Anderson/Woburn", " at ", "1:39pm"]} | rest] = trips


        assert [{"321", ~T[14:15:00], ["321", " ", "Outbound", " | Departs ", "North Station", " at ", "2:15pm", ", arrives at ", "Anderson/Woburn", " at ", "2:39pm"]},
                {"323", ~T[15:00:00], ["323", " ", "Outbound", " | Departs ", "North Station", " at ", "3:00pm", ", arrives at ", "Anderson/Woburn", " at ", "3:24pm"]},
                {"325", ~T[15:40:00], ["325", " ", "Outbound", " | Departs ", "North Station", " at ", "3:40pm", ", arrives at ", "Anderson/Woburn", " at ", "4:05pm"]},
                {"327", ~T[16:15:00], ["327", " ", "Outbound", " | Departs ", "North Station", " at ", "4:15pm", ", arrives at ", "Anderson/Woburn", " at ", "4:40pm"]},
                {"329", ~T[16:45:00], ["329", " ", "Outbound", " | Departs ", "North Station", " at ", "4:45pm", ", arrives at ", "Anderson/Woburn", " at ", "5:10pm"]},
                {"331", ~T[17:10:00], ["331", " ", "Outbound", " | Departs ", "North Station", " at ", "5:10pm", ", arrives at ", "Anderson/Woburn", " at ", "5:35pm"]},
                {"333", ~T[17:35:00], ["333", " ", "Outbound", " | Departs ", "North Station", " at ", "5:35pm", ", arrives at ", "Anderson/Woburn", " at ", "5:54pm"]},
                {"335", ~T[17:50:00], ["335", " ", "Outbound", " | Departs ", "North Station", " at ", "5:50pm", ", arrives at ", "Anderson/Woburn", " at ", "6:15pm"]},
                {"337", ~T[18:30:00], ["337", " ", "Outbound", " | Departs ", "North Station", " at ", "6:30pm", ", arrives at ", "Anderson/Woburn", " at ", "6:55pm"]},
                {"221", ~T[18:55:00], ["221", " ", "Outbound", " | Departs ", "North Station", " at ", "6:55pm", ", arrives at ", "Anderson/Woburn", " at ", "7:20pm"]},
                {"339", ~T[19:25:00], ["339", " ", "Outbound", " | Departs ", "North Station", " at ", "7:25pm", ", arrives at ", "Anderson/Woburn", " at ", "7:49pm"]},
                {"341", ~T[20:35:00], ["341", " ", "Outbound", " | Departs ", "North Station", " at ", "8:35pm", ", arrives at ", "Anderson/Woburn", " at ", "8:59pm"]},
                {"343", ~T[21:45:00], ["343", " ", "Outbound", " | Departs ", "North Station", " at ", "9:45pm", ", arrives at ", "Anderson/Woburn", " at ", "10:09pm"]},
                {"345", ~T[22:55:00], ["345", " ", "Outbound", " | Departs ", "North Station", " at ", "10:55pm", ", arrives at ", "Anderson/Woburn", " at ", "11:19pm"]},
                {"347", ~T[00:15:00], ["347", " ", "Outbound", " | Departs ", "North Station", " at ", "12:15am", ", arrives at ", "Anderson/Woburn", " at ", "12:39am"]}] = rest
      end
    end

    test "returns outbound results for origin destination" do
      use_cassette "anderson_woburn_to_north_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        trips = CommuterRailMapper.map_trip_options("Anderson/ Woburn", "place-north", :weekday, @test_date)
        assert [{"300", ~T[05:56:00], ["300", " ", "Inbound", " | Departs ", "Anderson/Woburn", " at ", "5:56am", ", arrives at ", "North Station", " at ", "6:22am"]},
                {"302", ~T[06:36:00], ["302", " ", "Inbound", " | Departs ", "Anderson/Woburn", " at ", "6:36am", ", arrives at ", "North Station", " at ", "7:01am"]},
                {"304", ~T[07:01:00], ["304", " ", "Inbound", " | Departs ", "Anderson/Woburn", " at ", "7:01am", ", arrives at ", "North Station", " at ", "7:27am"]},
                {"306", ~T[07:19:00], ["306", " ", "Inbound", " | Departs ", "Anderson/Woburn", " at ", "7:19am", ", arrives at ", "North Station", " at ", "7:47am"]},
                {"308", ~T[07:41:00], ["308", " ", "Inbound", " | Departs ", "Anderson/Woburn", " at ", "7:41am", ", arrives at ", "North Station", " at ", "8:06am"]},
                {"310", ~T[08:01:00], ["310", " ", "Inbound", " | Departs ", "Anderson/Woburn", " at ", "8:01am", ", arrives at ", "North Station", " at ", "8:21am"]},
                {"392", ~T[08:21:00], ["392", " ", "Inbound", " | Departs ", "Anderson/Woburn", " at ", "8:21am", ", arrives at ", "North Station", " at ", "8:47am"]},
                {"312", ~T[08:41:00], ["312", " ", "Inbound", " | Departs ", "Anderson/Woburn", " at ", "8:41am", ", arrives at ", "North Station", " at ", "9:06am"]},
                {"314", ~T[09:06:00], ["314", " ", "Inbound", " | Departs ", "Anderson/Woburn", " at ", "9:06am", ", arrives at ", "North Station", " at ", "9:31am"]} | _t] = trips
      end
    end

    test "returns error for invalid origin destination combo" do
      assert :error = CommuterRailMapper.map_trip_options("place-north", "Providence", :weekday, @test_date)
    end

    test "returns saturday results" do
      use_cassette "waltham_to_porter_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        trips = CommuterRailMapper.map_trip_options("Waltham", "place-portr", :saturday, @test_date)
        assert [{"1400", ~T[07:38:00], ["1400", " ", "Inbound", " | Departs ", "Waltham", " at ", "7:38am", ", arrives at ", "Porter", " at ", "7:50am"]},
                {"1402", ~T[09:53:00], ["1402", " ", "Inbound", " | Departs ", "Waltham", " at ", "9:53am", ", arrives at ", "Porter", " at ", "10:05am"]},
                {"1404", ~T[11:58:00], ["1404", " ", "Inbound", " | Departs ", "Waltham", " at ", "11:58am", ", arrives at ", "Porter", " at ", "12:10pm"]},
                {"1406", ~T[14:23:00], ["1406", " ", "Inbound", " | Departs ", "Waltham", " at ", "2:23pm", ", arrives at ", "Porter", " at ", "2:35pm"]},
                {"1408", ~T[16:48:00], ["1408", " ", "Inbound", " | Departs ", "Waltham", " at ", "4:48pm", ", arrives at ", "Porter", " at ", "5:00pm"]},
                {"1410", ~T[19:18:00], ["1410", " ", "Inbound", " | Departs ", "Waltham", " at ", "7:18pm", ", arrives at ", "Porter", " at ", "7:30pm"]},
                {"1412", ~T[22:53:00], ["1412", " ", "Inbound", " | Departs ", "Waltham", " at ", "10:53pm", ", arrives at ", "Porter", " at ", "11:05pm"]} | _t] = trips
      end
    end

    test "returns sunday results" do
      use_cassette "porter_to_waltham_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        trips = CommuterRailMapper.map_trip_options("place-portr", "Waltham", :sunday, @test_date)
        assert [{"2401", ~T[08:45:00], ["2401", " ", "Outbound", " | Departs ", "Porter", " at ", "8:45am", ", arrives at ", "Waltham", " at ", "8:57am"]},
                {"2403", ~T[10:55:00], ["2403", " ", "Outbound", " | Departs ", "Porter", " at ", "10:55am", ", arrives at ", "Waltham", " at ", "11:07am"]},
                {"2405", ~T[13:20:00], ["2405", " ", "Outbound", " | Departs ", "Porter", " at ", "1:20pm", ", arrives at ", "Waltham", " at ", "1:32pm"]},
                {"2407", ~T[15:40:00], ["2407", " ", "Outbound", " | Departs ", "Porter", " at ", "3:40pm", ", arrives at ", "Waltham", " at ", "3:52pm"]},
                {"2409", ~T[17:55:00], ["2409", " ", "Outbound", " | Departs ", "Porter", " at ", "5:55pm", ", arrives at ", "Waltham", " at ", "6:07pm"]},
                {"2411", ~T[20:05:00], ["2411", " ", "Outbound", " | Departs ", "Porter", " at ", "8:05pm", ", arrives at ", "Waltham", " at ", "8:17pm"]},
                {"2413", ~T[23:40:00], ["2413", " ", "Outbound", " | Departs ", "Porter", " at ", "11:40pm", ", arrives at ", "Waltham", " at ", "11:52pm"]}] = trips
      end
    end
  end
end
