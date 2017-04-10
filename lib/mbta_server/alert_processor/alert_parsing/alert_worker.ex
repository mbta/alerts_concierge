defmodule MbtaServer.AlertProcessor.AlertWorker do
  @moduledoc """
  Worker process used to periodically trigger the AlertParser
  to begin processing alerts.
  """
  use GenServer

  @alert_parser Application.get_env(:mbta_server, :alert_parser)

  @doc false
  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @doc """
  Initialize GenServer and schedule recurring alert parsing.
  """
  def init(_) do
    schedule_work()
    {:ok, nil}
  end

  @doc """
  Process alerts and then reschedule next time to process.
  """
  def handle_info(:work, _) do
    @alert_parser.process_alerts()
    schedule_work()
    {:noreply, nil}
  end

  defp schedule_work do
    Process.send_after(self(), :work, filter_interval())
  end

  defp filter_interval do
    alert_fetch_interval =
      case Application.get_env(:mbta_server, :alert_fetch_interval) do
        {:system, env_var, default} -> System.get_env(env_var) || default
        value -> value
      end
    String.to_integer(alert_fetch_interval)
  end
end
