import Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws.Mock
