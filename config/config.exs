# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

# By default, the umbrella project as well as each child
# application will require this configuration file, ensuring
# they all use the same configuration.
import_config "../apps/alert_processor/config/config.exs"
import_config "../apps/concierge_site/config/config.exs"

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :sentry,
  dsn: {:system, "SENTRY_DSN"},
  environment_name: {:system, "SENTRY_ENV"},
  included_environments: ~w(prod dev dev-green),
  in_app_module_allow_list: [AlertProcessor, ConciergeSite],
  json_library: Poison

config :logger, backends: [:console, Sentry.LoggerBackend]

keycloak_base_opts = [
  fetch_userinfo: true,
  userinfo_uid_field: "preferred_username",
  response_type: "code",
  scope: "openid email profile roles web-origins"
]

config :ueberauth, Ueberauth,
  providers: [
    keycloak: {Ueberauth.Strategy.OIDC, keycloak_base_opts},
    edit_password:
      {Ueberauth.Strategy.OIDC,
       Keyword.merge(keycloak_base_opts,
         callback_path: "/account/edit",
         request_params: %{kc_action: "UPDATE_PASSWORD"}
       )},
    update_profile:
      {Ueberauth.Strategy.OIDC,
       Keyword.merge(keycloak_base_opts,
         callback_path: "/account/edit",
         request_params: %{kc_action: "MBTA_UPDATE_PROFILE"}
       )},
    register:
      {Ueberauth.Strategy.OIDC,
       Keyword.merge(keycloak_base_opts,
         callback_path: "/auth/keycloak/callback",
         scope: "openid"
       )}
  ]
