use Mix.Config

config :alert_processor, database_url: {:system, "DATABASE_URL_PROD"}
# Do not print debug messages in production
config :logger,
  level: :info,
  truncate: :infinity,
  backends: [{Logger.Backend.Logentries, :logentries}, :console]

config :logger, :logentries,
  connector: Logger.Backend.Logentries.Output.SslKeepOpen,
  host: 'data.logentries.com',
  port: 443,
  token: "${LOGENTRIES_TOKEN}",
  format: "$dateT$time [$level]$levelpad node=$node $metadata$message\n"

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws
