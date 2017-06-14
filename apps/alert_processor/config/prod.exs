use Mix.Config

# Do not print debug messages in production
config :logger,
  level: :info,
  backends: [{Logger.Backend.Logentries, :logentries}, :console]

config :logger, :logentries,
  connector: Logger.Backend.Logentries.Output.SslKeepOpen,
  host: 'data.logentries.com',
  port: 443,
  token: System.get_env("LOGENTRIES_TOKEN"),
  format: "$dateT$time [$level]$levelpad node=$node $metadata$message\n"

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws

# Finally import the config/prod.secret.exs
# which should be versioned separately.
import_config "prod.secret.exs"
