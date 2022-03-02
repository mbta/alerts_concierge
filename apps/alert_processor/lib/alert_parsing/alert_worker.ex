defmodule AlertProcessor.AlertWorker do
  @moduledoc """
  Main worker that periodically calls `AlertParser` to fetch and process the appropriate group of
  alerts, based on when each group was last processed.
  """

  use GenServer
  alias AlertProcessor.{Lock, Model.Metadata}
  require Logger

  # Milliseconds to wait between checking whether any duration types need to be processed
  @check_interval 3_000

  # Defines the alert duration types and minimum seconds that should elapse between processing
  @frequencies %{recent: 10, older: 60, oldest: 600}

  defmodule State do
    @moduledoc false
    @type t :: %{
            check_interval: non_neg_integer | nil,
            frequencies: %{atom => non_neg_integer},
            now_fn: (() -> DateTime.t()),
            process_fn: (AlertProcessor.AlertFilters.duration_type() -> any)
          }

    @keys [:check_interval, :frequencies, :now_fn, :process_fn]
    @enforce_keys @keys
    defstruct @keys
  end

  @doc false
  def start_link(opts) do
    state = %State{
      check_interval: Keyword.get(opts, :check_interval, @check_interval),
      frequencies: Keyword.get(opts, :frequencies, @frequencies),
      now_fn: Keyword.get(opts, :now_fn, &DateTime.utc_now/0),
      process_fn: Keyword.get(opts, :process_fn, &AlertProcessor.AlertParser.process_alerts/1)
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  @impl GenServer
  def init(state) do
    schedule_check(state)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:check, state) do
    log("event=check_start")

    Lock.acquire(__MODULE__, fn
      :ok ->
        process_alerts(state)

      :error ->
        log("event=skip reason=lock_in_use")
    end)

    schedule_check(state)
    log("event=check_end")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_message, state) do
    {:noreply, state}
  end

  defp process_alerts(%{frequencies: frequencies, process_fn: process_fn, now_fn: now_fn}) do
    now = now_fn.()
    last_times = get_last_processed_times()

    [{most_stale_type, staleness} | _] =
      frequencies
      |> Stream.map(fn {duration_type, frequency} ->
        case Map.get(last_times, duration_type) do
          nil -> {duration_type, :infinite}
          last_time -> {duration_type, DateTime.diff(now, last_time) - frequency}
        end
      end)
      |> Enum.sort_by(&elem(&1, 1), &>/2)

    if staleness >= 0 do
      log("event=process duration_type=#{most_stale_type} seconds_outdated=#{staleness}")
      process_fn.(most_stale_type)
      update_last_processed_time(most_stale_type, now_fn.())
    else
      log("event=skip reason=no_stale_types")
    end
  end

  defp get_last_processed_times do
    Metadata.get(__MODULE__)
    |> Map.get("last_processed_times", %{})
    |> Stream.map(fn {key, value} ->
      {:ok, datetime, 0} = DateTime.from_iso8601(value)
      {String.to_existing_atom(key), datetime}
    end)
    |> Enum.into(%{})
  end

  defp update_last_processed_time(duration_type, datetime) do
    key = Atom.to_string(duration_type)
    value = DateTime.to_iso8601(datetime)

    new_meta =
      Metadata.get(__MODULE__)
      |> Map.put_new("last_processed_times", %{})
      |> put_in(["last_processed_times", key], value)

    Metadata.put(__MODULE__, new_meta)
  end

  defp schedule_check(%State{check_interval: nil}), do: :ok

  defp schedule_check(%State{check_interval: check_interval}) do
    Process.send_after(self(), :check, check_interval)
  end

  defp log(message), do: Logger.info("AlertWorker #{message}")
end
