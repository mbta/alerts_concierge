defmodule AlertProcessor.ApiClientTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias AlertProcessor.{ApiClient}

  setup_all do
    Application.stop(:alert_processor)
    on_exit(self(), fn() -> {:ok, _} = Application.ensure_all_started(:alert_processor) end)
    HTTPoison.start
    :ok
  end

  test "get_alerts/0 returns list of alerts if successful" do
    use_cassette "get_alerts", clear_mock: true do
      assert {[_ | _], [_ | _]} = ApiClient.get_alerts
    end
  end
end
