defmodule SystemMetricsTest do
  use ExUnit.Case

  describe "SystemMetrics" do
    test "start/2" do
      {:error, {status, pid}} = SystemMetrics.start(nil, nil)
      assert status == :already_started
      assert Process.alive?(pid)
    end

    test "can start without :meter in enviroment" do
      Application.delete_env(:system_metrics, :meter)
      {:error, {status, pid}} = SystemMetrics.start(nil, nil)
      assert status == :already_started
      assert Process.alive?(pid)
    end
  end
end
