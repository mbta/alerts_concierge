defmodule MbtaServer.AlertProcessor.ApiClientTest do
  use MbtaServer.Web.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias MbtaServer.AlertProcessor.{ApiClient}

  setup_all do
    HTTPoison.start
  end

  test "get_alerts/0 returns list of alerts if successful" do
    use_cassette "get_alerts" do
      assert [_h | _t] = ApiClient.get_alerts
    end
  end
end
