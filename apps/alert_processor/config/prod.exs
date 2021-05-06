use Mix.Config

config :alert_processor, database_url: {:system, "DATABASE_URL_PROD"}

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws

# Config for db migration function
config :alert_processor, :migration_task, AlertProcessor.ReleaseTasks
