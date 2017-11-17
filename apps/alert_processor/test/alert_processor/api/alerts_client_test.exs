defmodule AlertProcessor.AlertsClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias AlertProcessor.{AlertsClient}

  test "get_alerts/0 returns list of alerts if successful" do
    use_cassette "get_alerts_enhanced_json", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert {:ok, [_h | _t], 1498234472} = AlertsClient.get_alerts()
    end
  end

  test "get_alerts/0 can use the v2 format as well" do
    use_cassette "get_alerts_enhanced_json_v2", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert {:ok, [%{"id" => "114302", "effect" => "NO_SERVICE"} | _t], 1510944995} = AlertsClient.get_alerts()
    end
  end
end
