import Config

config :concierge_site, ConciergeSite.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json",
  root: ".",
  server: true,
  version: Application.spec(:concierge_site, :vsn)

config :concierge_site, :redirect_http?, true

config :logger, level: :info, truncate: :infinity

config :logger, :console,
  level: :info,
  format: "$dateT$time [$level]$levelpad node=$node $metadata$message\n",
  metadata: [:request_id, :ip]

config :ehmon, :report_mf, {:ehmon, :info_report}

config :concierge_site, ConciergeSite.Dissemination.Mailer, adapter: Bamboo.SesAdapter

# Mailchimp
config :concierge_site, mailchimp_api_client: HTTPoison
