defmodule MbtaServer.AlertProcessor do
  @moduledoc """
  Supervisor for managing child processes which facilitate the fetching
  of alerts from the api as well as processing the alerts to be sent
  to the correct users.
  """
  use Supervisor
  alias MbtaServer.AlertProcessor.AlertCache

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(AlertCache, [])
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
