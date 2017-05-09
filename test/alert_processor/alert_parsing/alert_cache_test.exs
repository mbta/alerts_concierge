defmodule MbtaServer.AlertProcessor.AlertCacheTest do
  use ExUnit.Case

  alias MbtaServer.AlertProcessor.{AlertCache}

  @old_alerts %{"1" => %{id: "1"}, "2" => %{id: "2"}}
  @new_alerts %{"2" => %{id: "2"}}

  setup do
    {:ok, pid} = AlertCache.start_link([name: __MODULE__])
    {:ok, pid: pid}
  end

  test "update_cache/1 returns empty lists if no alerts passed", %{pid: pid} do
    assert {[], []} == AlertCache.update_cache(pid, %{})
  end

  test "update_cache/1 returns list of new alerts", %{pid: pid} do
    assert {[%{id: "1"}, %{id: "2"}], []} == AlertCache.update_cache(pid, @old_alerts)
  end

  test "update_cache/1 returns list of new and removed alerts", %{pid: pid} do
    assert {[%{id: "1"}, %{id: "2"}], []} == AlertCache.update_cache(pid, @old_alerts)
    assert {[%{id: "2"}], ["1"]} == AlertCache.update_cache(pid, @new_alerts)
  end

  test "update_cache/1 returns list of new and updated alerts, and a list of removed and updated alert ids", %{pid: pid} do
    old_alerts = %{"1" => %{id: "1"}, "2" => %{id: "2"}, "3" => %{id: "3"}}
    updated_alert = %{id: "2", updated_at: "2017-04-25T21:30:28-04:00"}
    updated_alerts = %{
      "1" => %{id: "1"},
      "2" => updated_alert
    }

    assert {[%{id: "1"}, %{id: "2"}, %{id: "3"}], []} == AlertCache.update_cache(pid, old_alerts)
    assert {[%{id: "1"}, updated_alert], ["3", updated_alert.id]} == AlertCache.update_cache(pid, updated_alerts)
  end
end
