defmodule MbtaServer.AlertProcessor do
  @moduledoc """
  Supervisor for alert processor processes.
  """
  use Supervisor
  alias MbtaServer.AlertProcessor.AlertCache

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(AlertCache, [:alert_cache])
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
