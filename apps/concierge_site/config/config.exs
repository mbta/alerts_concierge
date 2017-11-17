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
  pubsub: [name: ConciergeSite.PubSub,
           adapter: Phoenix.PubSub.PG2]

config :concierge_site, temp_state_key: {:system, "TEMP_STATE_KEY", "top_secret_temp_state_key"}

# Bamboo config for emails
config :concierge_site, ConciergeSite.Dissemination.Mailer,
  adapter: Bamboo.LocalAdapter,
  deliver_later_strategy: ConciergeSite.Dissemination.DeliverLaterStrategy

config :concierge_site, ConciergeSite.Dissemination.DummyMailer,
  adapter: ConciergeSite.Dissemination.NullAdapter,
  deliver_later_strategy: ConciergeSite.Dissemination.DeliverLaterStrategy

config :concierge_site, send_from_email: {:system, "SENDER_EMAIL_ADDRESS", "developer@mbta.com"}

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

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
    default: [
      :reset_password,
      :unsubscribe,
      :disable_account,
      :full_permissions,
      :manage_subscriptions
    ],
    admin: [
      :customer_support,
      :application_administration
    ]
  }

config :guardian_db, GuardianDb,
  repo: AlertProcessor.Repo,
  schema_name: "guardian_tokens",
  sweep_interval: 120

config :concierge_site, mail_template_dir: Path.join(~w(#{__DIR__} /../ generated_templates))

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
