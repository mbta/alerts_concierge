use Mix.Config

config :alert_processor, database_url: {:system, "DATABASE_URL_PROD"}

# Configure your database
config :alert_processor, AlertProcessor.Repo, pool_size: 50

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws

# Config for db migration function
config :alert_processor, :migration_task, AlertProcessor.ReleaseTasks
