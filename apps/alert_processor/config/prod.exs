use Mix.Config

# Do not print debug messages in production
config :logger, level: :info

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws

# Finally import the config/prod.secret.exs
# which should be versioned separately.
import_config "prod.secret.exs"
