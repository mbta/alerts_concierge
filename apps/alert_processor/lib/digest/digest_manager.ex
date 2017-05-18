defmodule AlertProcessor.DigestManager do
  @moduledoc false
  use GenServer
  alias AlertProcessor.{AlertCache, DigestBuilder,
    DigestSerializer, DigestDispatcher, Helpers}
  alias Helpers.DateTimeHelper

  @digest_interval 604_800 # 1 Week in seconds
  @digest_day 7
  @digest_time ~T[15:00:00]

  def start_link do
    GenServer.start_link(__MODULE__, @digest_interval, [name: __MODULE__])
  end

  def init(state) do
    next_digest_ms = DateTimeHelper.seconds_until_next_digest(
      @digest_interval,
      @digest_day,
      @digest_time,
      {Date.utc_today(), Time.utc_now()}) * 1000

    Process.send_after(self(), :send_digests, next_digest_ms)
    {:ok, state}
  end

  def handle_info(:send_digests, interval) do
    AlertCache.get_alerts()
    |> DigestBuilder.build_digests()
    |> DigestSerializer.serialize()
    |> DigestDispatcher.send_emails()
    Process.send_after(self(), :send_digests, interval * 1000)
    {:noreply, interval}
  end
end
