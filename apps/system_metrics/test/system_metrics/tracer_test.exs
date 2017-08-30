defmodule SystemMetrics.TracerTest do
  @meter Application.get_env(:system_metrics, :meter)
  use ExUnit.Case
  alias SystemMetrics.Tracer

  describe "SystemMetrics.Tracer" do
    setup do
      @meter.clear()
    end

    test "trace" do
      result = Tracer.trace(&test_func/0, "test_label")

      collected_data = @meter.dump()

      assert collected_data[{:histogram, "test_label"}] >= 3
      assert :return_value == result
    end

    defp test_func do
      :timer.sleep(3)
      :return_value
    end
  end
end
