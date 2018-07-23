use Mix.Config

# Print only warnings and errors during test
config :logger, level: :warn

config :alert_processor,
  database_url:
    {:system, "DATABASE_URL_TEST",
     "postgresql://postgres:postgres@localhost:5432/alert_concierge_test"}

# Configure your database
config :alert_processor, AlertProcessor.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws.Mock

# Config for alert parser
config :alert_processor, :alert_parser, AlertProcessor.AlertParserMock

config :alert_processor, :mailer, AlertProcessor.MailerMock

config :alert_processor, database_url: {:system, "DATABASE_URL_TEST"}

config :alert_processor, :notification_window_filter, AlertProcessor.NotificationWindowFilterMock

config :alert_processor,
  pool_size: 0,
  overflow: 0

config :exvcr,
  vcr_cassette_library_dir: "test/fixture/vcr_cassettes",
  custom_cassette_library_dir: "test/fixture/custom_cassettes",
  filter_request_headers: ["x-api-key"]
