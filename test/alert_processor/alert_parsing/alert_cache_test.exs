defmodule MbtaServer.AlertProcessor.AlertCacheTest do
  use ExUnit.Case

  alias MbtaServer.AlertProcessor.{AlertCache}

  @old_alerts %{"1" => %{id: "1"}, "2" => %{id: "2"}}
  @new_alerts %{"2" => %{id: "2"}}

  setup do
    {:ok, pid} = AlertCache.start_link()

    {:ok, pid: pid}
  end

  test "Instantiates with empty new and removed lists", %{pid: pid} do
    assert :sys.get_state(pid) == %{alerts: %{}}
  end

  test "update_cache/1 returns empty lists if no alerts passed", %{pid: pid} do
    {[], []} = AlertCache.update_cache(pid, %{})
  end

  test "update_cache/1 returns list of new alerts", %{pid: pid} do
    {[%{id: "1"}, %{id: "2"}], []} = AlertCache.update_cache(pid, @old_alerts)
  end

  test "update_cache/1 returns lists of new and removed alerts", %{pid: pid} do
    {[%{id: "1"}, %{id: "2"}], []} = AlertCache.update_cache(pid, @old_alerts)
    {[%{id: "2"}], ["1"]} = AlertCache.update_cache(pid, @new_alerts)
  end
end
