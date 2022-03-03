import Config

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws

# Config for db migration function
config :alert_processor, :migration_task, AlertProcessor.ReleaseTasks
