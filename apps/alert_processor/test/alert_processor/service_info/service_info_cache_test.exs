defmodule AlertProcessor.ServiceInfoCacheTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias AlertProcessor.ServiceInfoCache

  test "get_subway_info/0 returns subway branch lists" do
    use_cassette "service_info", custom: true, clear_mock: true do
      ServiceInfoCache.start_link()
      assert {:ok, %{
        {"Blue", 1} => [{_, _} | _],
        {"Green-B", 0} => [{_, _}| _],
        {"Green-C", 0} => [{_, _}| _],
        {"Green-D", 0} => [{_, _}| _],
        {"Green-E", 0} => [{_, _}| _],
        {"Mattapan", 0} => [{_, _}| _],
        {"Orange", 1} => [{_, _}| _],
        {"Red", 1} => [{_, _}| _]
      }} = ServiceInfoCache.get_subway_info()
    end
  end
end
