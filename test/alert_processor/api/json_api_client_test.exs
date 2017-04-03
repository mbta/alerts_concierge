defmodule MbtaServer.AlertProcessor.JsonApiClientTest do
  use MbtaServer.Web.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias MbtaServer.AlertProcessor.{JsonApiClient}

  setup_all do
    HTTPoison.start
  end

  test "get_alerts/0 returns list of alerts if successful" do
    use_cassette "get_alerts" do
      assert [_h | _t] = JsonApiClient.get_alerts
    end
  end
end
