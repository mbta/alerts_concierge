defmodule SystemMetrics.PlugTest do
  @meter Application.get_env(:system_metrics, :meter)
  use ExUnit.Case

  describe "SystemMetrics.Plug" do
    setup do
      @meter.clear()
    end

    test "init/2" do
      assert SystemMetrics.Plug.init([]) == []
    end

    test "request_metrics/3" do

      # make a fake request that generates an error
      conn = SystemMetrics.Plug.call(%Plug.Conn{status: 500}, [])

      # wait for a brief moment
      :timer.sleep(5)

      # make sure the before send callback is called
      callback = List.first(conn.before_send)
      callback.(conn)

      # get data from elixir
      collected_data = @meter.dump()

      # assert that we have the expected data
      assert collected_data[{:counter, "errors"}] == 1
      assert collected_data[{:counter, "req_count"}] == 1
      assert collected_data[{:histogram, "resp_time"}] >= 5
    end
  end
end
