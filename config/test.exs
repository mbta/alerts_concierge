use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mbta_server, MbtaServer.Web.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :mbta_server, MbtaServer.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

# Bamboo
config :mbta_server, MbtaServer.Mailer,
  adapter: Bamboo.TestAdapter

config :mbta_server, MbtaServer.AlertProcessor.HoldingQueue,
  filter_interval: 100 # 0.1 sec

# Config for ExAws lib
config :mbta_server, :ex_aws, ExAws.Mock

config :guardian, Guardian, secret_key: "top_secret_key"
# Config for alert parser
config :mbta_server, :alert_parser, MbtaServer.AlertProcessor.AlertParserMock
