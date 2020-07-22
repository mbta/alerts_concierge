defmodule AlertProcessor.AlertWorker do
  @moduledoc """
  Worker process used to periodically trigger the AlertParser
  to begin processing alerts.
  """
  require Logger

  use GenServer
  alias AlertProcessor.Helpers.ConfigHelper

  @alert_parser Application.get_env(:alert_processor, :alert_parser)
  @older_duration_frequency 5

  @doc false
  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @doc """
  Initialize GenServer and schedule recurring alert parsing.
  """
  def init(_) do
    schedule_work(1, DateTime.utc_now())
    {:ok, nil}
  end

  @doc """
  Process alerts and then reschedule next time to process.
  Every fifth run it will pass :older to process_alerts, otherwise it passes :recent.
  """
  def handle_info({:work, count, last_process_oldest_alerts_time}, _) do
    Logger.info("Alerts ready to be processed")

    # process older or recent alerts
    alert_duration_type = if count == @older_duration_frequency, do: :older, else: :recent
    count = if count == @older_duration_frequency, do: 0, else: count
    @alert_parser.process_alerts(alert_duration_type)

    # process older alerts once per hour
    last_process_oldest_alerts_time = process_oldest_alerts(last_process_oldest_alerts_time)

    # schedule next run
    schedule_work(count + 1, last_process_oldest_alerts_time)

    Logger.info("Alert processing completed and next run scheduled")
    {:noreply, nil}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp process_oldest_alerts(last_process_oldest_alerts_time) do
    if DateTime.diff(DateTime.utc_now(), last_process_oldest_alerts_time, :second) > 3_600 do
      Logger.info(fn ->
        "Starting the oldest alert processing phase"
      end)

      @alert_parser.process_alerts(:oldest)
      DateTime.utc_now()
    else
      last_process_oldest_alerts_time
    end
  end

  defp schedule_work(count, last_process_oldest_alerts_time) do
    Process.send_after(self(), {:work, count, last_process_oldest_alerts_time}, filter_interval())
  end

  defp filter_interval do
    ConfigHelper.get_int(:alert_fetch_interval)
  end
end
