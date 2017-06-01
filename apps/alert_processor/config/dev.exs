use Mix.Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# AWS
config :ex_aws,
  access_key_id: ["STAGING_ACCESS_KEY_ID", :instance_role],
  secret_access_key: ["STAGING_SECRET_ACCESS_KEY", :instance_role]

# Bamboo
config :alert_processor, AlertProcessor.NotificationMailer,
  adapter: Bamboo.LocalAdapter

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws

config :alert_processor,
  asset_url: "https://s3.amazonaws.com/mbta-assets"
