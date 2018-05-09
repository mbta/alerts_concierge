defmodule AlertProcessor.Supervisor do
  @moduledoc """
  Supervisor for managing child processes which facilitate the fetching
  of alerts from the api as well as processing the alerts to be sent
  to the correct users.
  """
  use Supervisor
  alias AlertProcessor.{
    AlertCache,
    AlertWorker,
    SendingQueue,
    NotificationWorker,
    ServiceInfoCache,
    SmsOptOutWorker,
    Metrics
  }

  @worker_pool_size Application.get_env(:alert_processor, :pool_size)
  @worker_pool_overflow Application.get_env(:alert_processor, :overflow)

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    import Supervisor.Spec

    message_worker_config = [
      name: {:local, :message_worker},
      worker_module: NotificationWorker,
      size: @worker_pool_size,
      max_overflow: @worker_pool_overflow
    ]

    children = [
      supervisor(Registry, [:unique, :mailer_process_registry]),
      supervisor(AlertProcessor.Repo, []),
      worker(ServiceInfoCache, []),
      worker(Metrics, []),
      worker(AlertWorker, []),
      worker(AlertCache, []),
      worker(SendingQueue, []),
      worker(SmsOptOutWorker, []),
      :poolboy.child_spec(:message_worker, message_worker_config, [])
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
