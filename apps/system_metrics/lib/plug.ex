defmodule SystemMetrics.Plug do
  @moduledoc """
  Plug for providing request metrics to exometer.
  """
  @behaviour Plug
  @meter Application.get_env(:system_metrics, :meter)
  @dialyzer [nowarn_function: [before_send: 1]]
  import Plug.Conn, only: [register_before_send: 2, put_private: 3]

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _config) do
    conn
    |> put_private(:metrics_before_time, System.monotonic_time) # set the before time at the beginning of request
    |> register_before_send(&before_send/1)
  end

  @spec before_send(Plug.Conn.t) :: Plug.Conn.t | no_return
  def before_send(conn) do
    # calculate the end time at end of request lifecycle
    after_time = System.monotonic_time
    # log response time
    diff = round((after_time - conn.private.metrics_before_time) / 1_000_000)
    @meter.update_histogram("resp_time", diff)

    # log requests per minute
    @meter.update_counter("req_count", 1, [reset_seconds: 60])

    # log errors per minute
    if conn.status >= 500 do
      @meter.update_counter("errors", 1, [reset_seconds: 60])
    end

    conn
  end
end
