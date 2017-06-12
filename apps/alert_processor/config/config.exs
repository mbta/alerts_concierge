# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :alert_processor,
  ecto_repos: [AlertProcessor.Repo]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Bamboo
config :alert_processor, AlertProcessor.NotificationMailer,
  adapter: Bamboo.LocalAdapter,
  from: "faizaan@intrepid.io"

config :alert_processor, AlertProcessor.DigestMailer,
  adapter: Bamboo.LocalAdapter,
  from: "faizaan@intrepid.io"

config :alert_processor, AlertProcessor,
  pool_size: 2,
  overflow: 1

# Configure your database
config :alert_processor, AlertProcessor.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 10

# Config for alert parser
config :alert_processor, :alert_parser, AlertProcessor.AlertParser
config :alert_processor, alert_fetch_interval: {:system, "ALERT_FETCH_INTERVAL", "60000"}
config :alert_processor, opted_out_list_fetch_interval: {:system, "OPTED_OUT_LIST_FETCH_INTERVAL", "300000"}
config :alert_processor, service_info_update_interval: {:system, "SERVICE_INFO_UPDATE_INTERVAL", "86400000"}
config :alert_processor, alert_api_url: {:system, "ALERT_API_URL", "http://s3.amazonaws.com/mbta-realtime-test/"}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
