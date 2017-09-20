use Mix.Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws.Mock

config :alert_processor, database_url: {:system, "DATABASE_URL_DEV"}
