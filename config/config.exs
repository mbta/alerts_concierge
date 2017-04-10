# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :mbta_server,
  ecto_repos: [MbtaServer.Repo]

# Configures the endpoint
config :mbta_server, MbtaServer.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7U73UP3XMgn6IpcCcFls5SpkGk+jLN5dAAax/XYKoMMuC/PlfqK0n+NfS1n3MbrK",
  render_errors: [view: MbtaServer.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MbtaServer.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Bamboo
config :mbta_server, MbtaServer.Mailer,
  adapter: Bamboo.LocalAdapter

config :mbta_server, MbtaServer.AlertProcessor.HoldingQueue,
  filter_interval: 300_000 # 5 mins

# Configure your database
config :mbta_server, MbtaServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 10

# Config for alert parser
config :mbta_server, :alert_parser, MbtaServer.AlertProcessor.AlertParser

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
