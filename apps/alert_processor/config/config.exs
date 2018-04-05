# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :alert_processor,
  ecto_repos: [AlertProcessor.Repo],
  notification_window_filter: AlertProcessor.NotificationWindowFilter


config :paper_trail, repo: AlertProcessor.Repo, item_type: Ecto.UUID, originator_type: Ecto.UUID

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure your database
config :alert_processor, AlertProcessor.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 10

config :alert_processor, :mailer, AlertProcessor.Dissemination.Mailer

# Config for alert parser
config :alert_processor, :alert_parser, AlertProcessor.AlertParser
config :alert_processor, alert_fetch_interval: {:system, "ALERT_FETCH_INTERVAL", "60000"}
config :alert_processor, opted_out_list_fetch_interval: {:system, "OPTED_OUT_LIST_FETCH_INTERVAL", "3600000"}
config :alert_processor, service_info_update_interval: {:system, "SERVICE_INFO_UPDATE_INTERVAL", "86400000"}
config :alert_processor, alert_api_url: {:system, "ALERT_API_URL", "http://s3.amazonaws.com/mbta-realtime-test/alerts_enhanced.json"}
config :alert_processor, api_url: {:system, "API_URL", "https://dev.api.mbtace.com/"}
config :alert_processor, api_key: {:system, "API_KEY", nil}
config :alert_processor, database_url: {:system, "DATABASE_URL_DEV", "postgresql://postgres:postgres@localhost:5432/alert_concierge_dev"}

# Config for Rate Limiter. Scale: time period in ms. Limit: # of requests per time period. Send Rate: ms delay between send
config :alert_processor,
  pool_size: 2,
  overflow: 1,
  rate_limit_scale: {:system, "RATE_LIMIT_SCALE", "3600000"},
  rate_limit: {:system, "RATE_LIMIT", "30"},
  send_rate: {:system, "SEND_RATE", "100"}

# Config for db migration function
config :alert_processor, :migration_task, AlertProcessor.ReleaseTasks.Dev

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
