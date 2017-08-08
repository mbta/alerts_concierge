use Mix.Config

config :alert_processor, database_url: {:system, "DATABASE_URL_PROD"}
# Do not print debug messages in production
config :logger,
  level: :info,
  backends: [{Logger.Backend.Logentries, :logentries}, :console]

config :logger, :logentries,
  connector: Logger.Backend.Logentries.Output.SslKeepOpen,
  host: 'data.logentries.com',
  port: 443,
  token: "LOGENTRIES_TOKEN",
  format: "$dateT$time [$level]$levelpad node=$node $metadata$message\n"

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws

config :ex_aws,
  access_key_id: ["AWS_ACCESS_KEY", :instance_role],
  secret_access_key: ["AWS_SECRET_KEY", :instance_role]
