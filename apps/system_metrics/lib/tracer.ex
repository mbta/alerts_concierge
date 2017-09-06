defmodule SystemMetrics.Tracer do
  @moduledoc """
  module used for monitoring times taken
  for certain function calls to complete.
  """
  @meter Application.get_env(:system_metrics, :meter)

  def trace(operation, label) do
    start_time = System.monotonic_time()

    result = operation.()

    end_time = System.monotonic_time()
    diff = round((end_time - start_time) / 1_000_000)
    @meter.update_histogram(label, diff)

    result
  end
end
