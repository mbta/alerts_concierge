defmodule AlertProcessor.ApiClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias AlertProcessor.{ApiClient}

  test "get_alerts/0 returns list of alerts if successful" do
    use_cassette "get_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert {:ok, [_ | _], [_ | _]} = ApiClient.get_alerts
    end
  end
end
