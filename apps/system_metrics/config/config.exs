# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :sasl,
  sasl_error_logger: false

config :elixometer,
  reporter: ExometerDatadog.Reporter,
  metric_prefix: "concierge",
  env: Mix.env,
  update_frequency: 60_000

config :exometer_datadog, [
  api_key: {:system, "DD_API_KEY"},
  add_reporter: true,
  update_frequency: 15_000
]

config :system_metrics, :meter, Elixometer

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :holiday, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:holiday, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info

config :lager, [
  log_root: '../../',
  handlers: [
    lager_console_backend: :info
  ],
  crash_log: false
]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
import_config "#{Mix.env}.exs"
