defmodule AlertProcessor.ServiceInfoCacheTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.ServiceInfoCache

  setup_all do
    Application.stop(:alert_processor)
    on_exit(self(), fn() -> Application.start(:alert_processor) end)
    :ok
  end

  test "get_subway_info/0 returns subway branch lists" do
    use_cassette "service_info", custom: true, clear_mock: true do
      ServiceInfoCache.start_link()
      assert {:ok, %{
        "Blue" => [{_, _} | _],
        "Green-B" => [{_, _}| _],
        "Green-C" => [{_, _}| _],
        "Green-D" => [{_, _}| _],
        "Green-E" => [{_, _}| _],
        "Mattapan" => [{_, _}| _],
        "Orange" => [{_, _}| _],
        "Red" => [{_, _}| _]
      }} = ServiceInfoCache.get_subway_info()
    end
  end
end
