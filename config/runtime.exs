import Config

config :alert_processor, AlertProcessor.Repo,
  url: System.fetch_env!("DATABASE_URL_#{config_env() |> to_string() |> String.upcase()}")

if config_env() == :prod do
  config :concierge_site, ConciergeSite.Endpoint,
    url: [host: System.fetch_env!("HOST_URL"), port: 80],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE")

  config :concierge_site, ConciergeSite.Guardian,
    secret_key: System.fetch_env!("GUARDIAN_AUTH_KEY")

  config :concierge_site, ConciergeSite.ViewHelpers,
    google_tag_manager_id: System.fetch_env!("GOOGLE_TAG_MANAGER_ID")
end
