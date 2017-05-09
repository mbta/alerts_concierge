defmodule MbtaServer.AlertProcessor do
  @moduledoc """
  Supervisor for managing child processes which facilitate the fetching
  of alerts from the api as well as processing the alerts to be sent
  to the correct users.
  """
  use Supervisor
  alias MbtaServer.AlertProcessor.{
    AlertCache,
    AlertWorker,
    HoldingQueue,
    SendingQueue,
    NotificationWorker,
    QueueWorker,
    SmsOptOutWorker
  }

  @worker_pool_size Application.get_env(__MODULE__, :pool_size)
  @worker_pool_overflow Application.get_env(__MODULE__, :overflow)

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    message_worker_config = [
      name: {:local, :message_worker},
      worker_module: NotificationWorker,
      size: @worker_pool_size,
      max_overflow: @worker_pool_overflow
    ]

    children = [
      worker(AlertWorker, []),
      worker(AlertCache, []),
      worker(HoldingQueue, []),
      worker(SendingQueue, []),
      worker(QueueWorker, []),
      worker(SmsOptOutWorker, []),
      :poolboy.child_spec(:message_worker, message_worker_config, [])
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
