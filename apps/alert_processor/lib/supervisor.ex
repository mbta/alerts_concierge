defmodule AlertProcessor.Supervisor do
  @moduledoc """
  Supervisor for managing child processes which facilitate the fetching
  of alerts from the api as well as processing the alerts to be sent
  to the correct users.
  """
  use Supervisor

  alias AlertProcessor.{
    AlertWorker,
    CachedApiClient,
    SendingQueue,
    NotificationWorker,
    ServiceInfoCache,
    SmsOptOutWorker,
    Metrics,
    Reminders
  }

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    import Supervisor.Spec

    message_worker_config = [
      name: {:local, :message_worker},
      worker_module: NotificationWorker,
      size: Application.get_env(:alert_processor, :notification_workers)
    ]

    children = [
      supervisor(AlertProcessor.Repo, []),
      supervisor(ConCache, [
        [
          ttl_check: :timer.seconds(60),
          ttl: :timer.minutes(60)
        ],
        [name: CachedApiClient.cache_name()]
      ]),
      worker(ServiceInfoCache, []),
      worker(Metrics, []),
      worker(Reminders, []),
      worker(AlertWorker, []),
      worker(SendingQueue, []),
      worker(SmsOptOutWorker, []),
      :poolboy.child_spec(:message_worker, message_worker_config, [])
    ]

    opts = [strategy: :one_for_one]
    supervise(children, opts)
  end
end
