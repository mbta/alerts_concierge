defmodule MbtaServer.AlertProcessor.AlertParserTest do
  use MbtaServer.Web.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Bamboo.Test
  import MbtaServer.Factory
  alias MbtaServer.AlertProcessor.{AlertParser}

  setup_all do
    HTTPoison.start
  end

  test "process_alerts/1" do
    insert(:user, phone_number: nil)
    use_cassette "get_alerts" do
      [{:ok, _} | _t] = AlertParser.process_alerts
    end
  end
end
