defmodule AlertProcessor.AlertsClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias AlertProcessor.{AlertsClient}

  test "get_alerts/0 returns list of alerts if successful" do
    use_cassette "get_alerts_enhanced_json", clear_mock: true, match_requests_on: [:query] do
      assert {:ok, [_h | _t]} = AlertsClient.get_alerts()
    end
  end
end
