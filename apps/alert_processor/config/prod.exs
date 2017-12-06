use Mix.Config

config :alert_processor, database_url: {:system, "DATABASE_URL_PROD"}
# Do not print debug messages in production
config :logger,
  level: :info,
  truncate: :infinity,
  backends: [:console]

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws
