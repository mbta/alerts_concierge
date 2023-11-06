import Config

alias Helpers.RuntimeHelper

ex_aws =
  case(System.get_env("DISABLE_SMS_SENDING")) do
    "true" -> ExAws.Mock
    _ -> Application.get_env(:alert_processor, :ex_aws)
  end

mailer =
  case(System.get_env("DISABLE_EMAIL_SENDING")) do
    "true" -> AlertProcessor.MailerMock
    _ -> Application.get_env(:alert_processor, :mailer)
  end

config :alert_processor,
  ex_aws: ex_aws,
  mailer: mailer

config :alert_processor, AlertProcessor.Repo,
  url: System.fetch_env!("DATABASE_URL_#{config_env() |> to_string() |> String.upcase()}")

if base_uri = System.get_env("KEYCLOAK_BASE_URI") do
  config :concierge_site,
    keycloak_base_uri: base_uri

  keycloak_base_opts = [
    discovery_document_uri: System.fetch_env!("KEYCLOAK_WELL_KNOWN_OIDC"),
    client_id: System.fetch_env!("KEYCLOAK_CLIENT_ID"),
    client_secret: System.fetch_env!("KEYCLOAK_CLIENT_SECRET")
  ]

  realm = System.get_env("KEYCLOAK_REALM", "MBTA")

  config :ueberauth, Ueberauth.Strategy.OIDC,
    keycloak: keycloak_base_opts,
    edit_password: keycloak_base_opts,
    update_profile: keycloak_base_opts,
    register:
      Keyword.merge(keycloak_base_opts,
        request_uri: "#{base_uri}/auth/realms/#{realm}/protocol/openid-connect/registrations"
      )
end

if config_env() == :prod do
  config :concierge_site, ConciergeSite.Endpoint,
    url: [host: System.fetch_env!("HOST_URL"), port: 443, scheme: "https"],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

  config :concierge_site, ConciergeSite.Guardian,
    secret_key: System.fetch_env!("GUARDIAN_AUTH_KEY")

  config :concierge_site, ConciergeSite.ViewHelpers,
    google_tag_manager_id: System.fetch_env!("GOOGLE_TAG_MANAGER_ID")

  # Informizely
  config :concierge_site,
    informizely_site_id: System.fetch_env!("INFORMIZELY_SITE_ID")

  config :concierge_site,
    informizely_account_deleted_survey_id:
      System.fetch_env!("INFORMIZELY_ACCOUNT_DELETED_SURVEY_ID")
end
