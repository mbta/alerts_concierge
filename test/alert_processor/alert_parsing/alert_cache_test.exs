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
    {[], []} = AlertCache.update_cache(%{}, pid)
  end

  test "update_cache/1 returns list of new alerts", %{pid: pid} do
    {[%{id: "1"}, %{id: "2"}], []} = AlertCache.update_cache(@old_alerts, pid)
  end

  test "update_cache/1 returns lists of new and removed alerts", %{pid: pid} do
    {[%{id: "1"}, %{id: "2"}], []} = AlertCache.update_cache(@old_alerts, pid)
    {[%{id: "2"}], ["1"]} = AlertCache.update_cache(@new_alerts, pid)
  end
end
