# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

# General application configuration
config :alert_processor,
  ecto_repos: [AlertProcessor.Repo],
  notification_window_filter: AlertProcessor.NotificationWindowFilter,
  aws_rds_mod: ExAws.RDS

config :ex_aws, json_codec: Poison, debug_requests: true

config :paper_trail, repo: AlertProcessor.Repo, item_type: Ecto.UUID, originator_type: Ecto.UUID

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure your database
config :alert_processor, AlertProcessor.Repo, migration_timestamps: [type: :utc_datetime]

# Enable cyclic dependency on ConciergeSite mailer that can be bypassed in the test environment.
# These modules are not defined when AlertProcessor is run on its own.
config :alert_processor, :mailer, ConciergeSite.Dissemination.Mailer
config :alert_processor, :mailer_email, ConciergeSite.Dissemination.NotificationEmail

config :alert_processor,
  opted_out_list_fetch_interval: {:system, "OPTED_OUT_LIST_FETCH_INTERVAL", "3600000"}

config :alert_processor,
  service_info_update_interval: {:system, "SERVICE_INFO_UPDATE_INTERVAL", "86400000"}

config :alert_processor,
  alert_api_url:
    {:system, "ALERT_API_URL", "http://s3.amazonaws.com/mbta-realtime-test/alerts_enhanced.json"}

config :alert_processor, api_url: {:system, "API_URL", "https://api-dev.mbtace.com/"}
config :alert_processor, api_key: {:system, "API_KEY", nil}

config :alert_processor, user_update_sqs_queue_url: {:system, "USER_UPDATE_SQS_QUEUE_URL", ""}

# Number of workers for sending notifications
config :alert_processor, notification_workers: 40

# Config for db migration function
config :alert_processor, :migration_task, AlertProcessor.ReleaseTasks.Dev

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
