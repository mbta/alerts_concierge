defmodule AlertProcessor.Metrics do
  @moduledoc """
  Module used to retrieve application metrics and output them to a log every 5 minutes.
  """
  use GenServer
  require Logger
  alias AlertProcessor.Metrics.UserMetrics

  @doc false
  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @doc """
  Initialize GenServer and schedule recurring logging.
  """
  def init(_) do
    if enabled?() do
      schedule_work()
      {:ok, nil}
    else
      :ignore
    end
  end

  @doc """
  Fetch metrics and then reschedule next work.
  """
  def handle_info(:work, _) do
    schedule_work()
    [phone_count, email_count] = UserMetrics.counts_by_type()
    Logger.info("user_metrics phone_count=#{phone_count} email_count=#{email_count}")
    {:noreply, nil}
  end

  defp schedule_work do
    five_minutes_in_ms = 5 * 60 * 1000
    Process.send_after(self(), :work, five_minutes_in_ms)
  end

  defp enabled?() do
    if Application.get_env(:alert_processor, :env) == :prod do
      true
    else
      false
    end
  end
end