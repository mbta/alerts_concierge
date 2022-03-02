defmodule AlertProcessor do
  @moduledoc "Application bootstrap"
  use Application

  def start(_type, _args) do
    with {:ok, pid} <- supervise() do
      Application.get_env(:alert_processor, :migration_task).migrate()
      {:ok, pid}
    end
  end

  defp supervise do
    message_worker_config = [
      name: {:local, :message_worker},
      worker_module: AlertProcessor.NotificationWorker,
      size: Application.get_env(:alert_processor, :notification_workers)
    ]

    alert_worker_config =
      if Application.get_env(:alert_processor, :process_alerts?, true),
        do: [],
        else: [check_interval: nil]

    children = [
      AlertProcessor.Repo,
      {ConCache,
       [
         name: AlertProcessor.CachedApiClient.cache_name(),
         global_ttl: :timer.minutes(60),
         ttl_check_interval: :timer.seconds(60)
       ]},
      AlertProcessor.ServiceInfoCache,
      AlertProcessor.SendingQueue,
      AlertProcessor.Reminders,
      {AlertProcessor.AlertWorker, alert_worker_config},
      AlertProcessor.SmsOptOutWorker,
      :poolboy.child_spec(:message_worker, message_worker_config, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
