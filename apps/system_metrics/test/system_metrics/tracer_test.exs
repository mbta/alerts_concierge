defmodule SystemMetrics.TracerTest do
  @meter Application.get_env(:system_metrics, :meter)
  use ExUnit.Case
  alias SystemMetrics.Tracer

  describe "SystemMetrics.Tracer" do
    setup do
      @meter.clear()
    end

    test "trace" do
      test_data = "Hello"
      result = Tracer.trace(fn() -> :timer.sleep(3); test_func(test_data) end, "test_label")

      collected_data = @meter.dump()

      assert collected_data[{:histogram, "test_label"}] >= 3
      assert result == test_func(test_data)
    end

    defp test_func(param) do
      param
    end
  end
end
