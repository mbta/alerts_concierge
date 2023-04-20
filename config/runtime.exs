import Config

config :alert_processor, AlertProcessor.Repo,
  url: System.fetch_env!("DATABASE_URL_#{config_env() |> to_string() |> String.upcase()}")

config :concierge_site, ConciergeSite.Endpoint,
  authentication_source: System.get_env("AUTHENTICATION_SOURCE", "local")

config :ueberauth, Ueberauth.Strategy.OIDC,
  keycloak: [
    fetch_userinfo: true,
    userinfo_uid_field: "preferred_username",
    discovery_document_uri: System.get_env("KEYCLOAK_WELL_KNOWN_OIDC"),
    client_id: System.get_env("KEYCLOAK_CLIENT_ID"),
    client_secret: System.get_env("KEYCLOAK_CLIENT_SECRET"),
    redirect_uri: System.get_env("KEYCLOAK_REDIRECT_URI"),
    logout_uri: System.get_env("KEYCLOAK_LOGOUT_URI"),
    response_type: "code",
    scope: "openid email profile roles web-origins"
  ]

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
