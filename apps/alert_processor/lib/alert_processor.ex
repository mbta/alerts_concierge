defmodule AlertProcessor do
  @moduledoc "Application bootstrap"
  use Application

  alias AlertProcessor.{
    AlertWorker,
    CachedApiClient,
    SendingQueue,
    NotificationWorker,
    ServiceInfoCache,
    SmsOptOutWorker,
    Reminders
  }

  def start(_type, _args) do
    with {:ok, pid} <- supervise() do
      Application.get_env(:alert_processor, :migration_task).migrate()
      {:ok, pid}
    end
  end

  defp supervise do
    import Supervisor.Spec

    message_worker_config = [
      name: {:local, :message_worker},
      worker_module: NotificationWorker,
      size: Application.get_env(:alert_processor, :notification_workers)
    ]

    alert_worker_config =
      if Application.get_env(:alert_processor, :process_alerts?, true),
        do: [],
        else: [[check_interval: nil]]

    children = [
      supervisor(AlertProcessor.Repo, []),
      supervisor(ConCache, [
        [
          name: CachedApiClient.cache_name(),
          global_ttl: :timer.minutes(60),
          ttl_check_interval: :timer.seconds(60)
        ]
      ]),
      worker(ServiceInfoCache, []),
      worker(SendingQueue, []),
      worker(Reminders, []),
      worker(AlertWorker, alert_worker_config),
      worker(SmsOptOutWorker, []),
      :poolboy.child_spec(:message_worker, message_worker_config, [])
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
