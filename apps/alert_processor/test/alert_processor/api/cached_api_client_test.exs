defmodule AlertProcessor.CachedApiClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias AlertProcessor.CachedApiClient

  test "schedule_for_trip/1 returns list of schedules if successful" do
    use_cassette "trip_schedule_orange_line",
      custom: true,
      clear_mock: true,
      match_requests_on: [:query] do
      assert {:ok, _schedule_data} = CachedApiClient.schedule_for_trip("Orange")
    end
  end
end
