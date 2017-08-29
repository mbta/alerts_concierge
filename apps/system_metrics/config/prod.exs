use Mix.Config

config :exometer_datadog, [
  api_key: "${DD_API_KEY}",
  add_reporter: true,
  update_frequency: 15_000
]
