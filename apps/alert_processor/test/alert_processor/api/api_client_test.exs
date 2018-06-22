defmodule AlertProcessor.ApiClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias AlertProcessor.{ApiClient}

  test "get_alerts/0 returns list of alerts if successful" do
    use_cassette "get_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert {:ok, [_ | _], [_ | _]} = ApiClient.get_alerts
    end
  end

  test "schedule_for_trip/1 returns list of schedules if successful" do
    use_cassette "trip_schedule_orange_line", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert {:ok, _schedule_data} = ApiClient.schedule_for_trip("Orange")
    end
  end

  test "subway_schedules_union/2 returns list of schedules and included parent stations if successful" do
    use_cassette "subway_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert {:ok, _schedule_data, _included_data} =
        ApiClient.subway_schedules_union("place-brntn", "place-qamnl")
    end
  end
end
