# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :concierge_site,
  namespace: ConciergeSite,
  ecto_repos: []

# Configures the endpoint
config :concierge_site, ConciergeSite.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wxQjfCkbnND+H2kYSmvtNl+77BiBDB3qM7ytsJaOTZp2aBcEhcGvdkoa55pYbER0",
  render_errors: [view: ConciergeSite.ErrorView, accepts: ~w(html json)],
  pubsub: [name: ConciergeSite.PubSub, adapter: Phoenix.PubSub.PG2]

config :concierge_site, :redirect_http?, false

# Bamboo config for emails
config :concierge_site, ConciergeSite.Dissemination.Mailer, adapter: Bamboo.LocalAdapter

config :concierge_site, send_from_email: {:system, "SENDER_EMAIL_ADDRESS", "alerts@mbta.com"}
config :concierge_site, send_from_name: {:system, "SENDER_EMAIL_NAME", "T-Alerts"}

config :concierge_site, :external_urls,
  alerts: "https://www.mbta.com/alerts",
  faqs: "https://www.mbta.com/about-t-alerts",
  privacy: "https://www.mbta.com/policies/privacy-policy#4.6",
  support: "https://www.mbta.com/customer-support"

# Configures Elixir's Logger
config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  metadata: [:request_id]

# Include referrer in Logster request log
config :logster, :allowed_headers, ["referer"]

config :guardian, Guardian,
  allowed_algos: ["HS512"],
  verify_module: Guardian.JWT,
  issuer: "AlertsConcierge",
  ttl: {60, :minutes},
  allowed_drift: 2000,
  verify_issuer: true,
  secret_key: "${GUARDIAN_AUTH_KEY}",
  serializer: ConciergeSite.GuardianSerializer,
  hooks: GuardianDb,
  permissions: %{
    default: [],
    admin: [:all]
  }

config :guardian_db, GuardianDb,
  repo: AlertProcessor.Repo,
  schema_name: "guardian_tokens",
  sweep_interval: 120

config :concierge_site, mail_template_dir: Path.join(~w(#{__DIR__} /../ lib/mail_templates))

# Google Tag Manager
config :concierge_site, ConciergeSite.ViewHelpers,
  google_tag_manager_id: System.get_env("GOOGLE_TAG_MANAGER_ID")

# Rate Limiting
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

# Mailchimp
config :concierge_site, mailchimp_api_url: {:system, "MAILCHIMP_API_URL", ""}
config :concierge_site, mailchimp_api_key: {:system, "MAILCHIMP_API_KEY", ""}
config :concierge_site, mailchimp_list_id: {:system, "MAILCHIMP_LIST_ID", "abc123"}
config :concierge_site, mailchimp_api_client: ConciergeSite.Mailchimp.FakeClient

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
