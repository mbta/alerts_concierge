# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# By default, the umbrella project as well as each child
# application will require this configuration file, ensuring
# they all use the same configuration.
import_config "../apps/*/config/config.exs"

config :sentry,
  dsn: {:system, "SENTRY_DSN"},
  environment_name: {:system, "SENTRY_ENV"},
  included_environments: ~w(prod dev dev-green),
  in_app_module_whitelist: [AlertProcessor, ConciergeSite],
  json_library: Poison

config :logger, backends: [:console, Sentry.LoggerBackend]
