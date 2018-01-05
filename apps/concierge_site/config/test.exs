use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :concierge_site, ConciergeSite.Endpoint,
  http: [port: 4001],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

config :guardian, Guardian, secret_key: "top_secret_key"

config :concierge_site, ConciergeSite.Dissemination.Mailer,
  adapter: Bamboo.TestAdapter,
  deliver_later_strategy: Bamboo.ImmediateDeliveryStrategy

config :concierge_site, :sql_sandbox, true

# Google Tag Manager
config :concierge_site, ConciergeSite.ViewHelpers,
  google_tag_manager_id: "GOOGLE_TAG_MANAGER_ID"
