use Mix.Config

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :alert_processor, AlertProcessor.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

# Bamboo
config :alert_processor, AlertProcessor.NotificationMailer,
  adapter: Bamboo.TestAdapter

config :alert_processor, AlertProcessor.DigestMailer,
  adapter: Bamboo.TestAdapter

config :alert_processor, AlertProcessor.HoldingQueue,
  filter_interval: 100 # 0.1 sec

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws.Mock

# Config for alert parser
config :alert_processor, :alert_parser, AlertProcessor.AlertParserMock

config :alert_processor,
  asset_url: "https://example.com/assets"

