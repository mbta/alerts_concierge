defmodule AlertProcessor.AlertWorker do
  @moduledoc """
  Worker process used to periodically trigger the AlertParser
  to begin processing alerts.
  """
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
    schedule_work(1)
    {:ok, nil}
  end

  @doc """
  Process alerts and then reschedule next time to process.
  Every fifth run it will pass :older to process_alerts, otherwise it passes :recent.
  """
  def handle_info({:work, count}, _) do
    alert_duration_type = if count == @older_duration_frequency, do: :older, else: :recent
    count = if count == @older_duration_frequency, do: 0, else: count
    @alert_parser.process_alerts(alert_duration_type)
    schedule_work(count + 1)
    {:noreply, nil}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp schedule_work(count) do
    Process.send_after(self(), {:work, count}, filter_interval())
  end

  defp filter_interval do
    ConfigHelper.get_int(:alert_fetch_interval)
  end
end
