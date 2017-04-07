defmodule MbtaServer.AlertProcessor.AlertCacheTest do
  use ExUnit.Case

  alias MbtaServer.AlertProcessor.{AlertCache}

  setup do
    old_alerts = %{"1" => %{}, "2" => %{}}
    new_alerts = %{"2" => %{}}

    {:ok, cache} = AlertCache.start_link(:test_cache)

    {:ok, cache: cache, old_alerts: old_alerts, new_alerts: new_alerts}
  end

  test "Instantiates with empty new and removed lists", %{cache: cache} do
    assert :sys.get_state(cache) == %{alerts: %{}}
  end

  test "update_cache/1 returns empty lists if no alerts passed" do
    {[], []} = AlertCache.update_cache(:test_cache, %{})
  end

  test "update_cache/1 returns list of new alerts", %{old_alerts: old_alerts} do
    {[{"1", %{}}, {"2", %{}}], []} = AlertCache.update_cache(:test_cache, old_alerts)
  end

  test "update_cache/1 returns lists of new and removed alerts", %{old_alerts: old_alerts, new_alerts: new_alerts} do
    {[{"1", %{}}, {"2", %{}}], []} = AlertCache.update_cache(:test_cache, old_alerts)
    {[{"2", %{}}], [{"1", %{}}]} = AlertCache.update_cache(:test_cache, new_alerts)
  end
end
