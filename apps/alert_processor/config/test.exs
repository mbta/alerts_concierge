import Config

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :alert_processor, AlertProcessor.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox

# Config for ExAws lib
config :alert_processor, :ex_aws, ExAws.Mock

# Don't run periodic background alert processing
config :alert_processor, :process_alerts?, false

config :alert_processor, :mailer, AlertProcessor.MailerMock
config :alert_processor, :mailer_email, AlertProcessor.EmailMock

config :alert_processor, api_url: "https://api-dev.mbtace.com/"

config :alert_processor, :notification_window_filter, AlertProcessor.NotificationWindowFilterMock

config :alert_processor, notification_workers: 0, notification_worker_idle_wait: 50

config :alert_processor, :sql_sandbox, true

config :exvcr,
  vcr_cassette_library_dir: "test/fixture/vcr_cassettes",
  custom_cassette_library_dir: "test/fixture/custom_cassettes",
  filter_request_headers: ["x-api-key"]
