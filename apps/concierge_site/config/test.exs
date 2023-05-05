import Config

# Run a server for browser-based feature tests
config :concierge_site, ConciergeSite.Endpoint, server: true, http: [port: 4001]

# Print only warnings and errors during test
config :logger, level: :warn

config :concierge_site, ConciergeSite.Guardian, secret_key: "top_secret_key"
config :concierge_site, ConciergeSite.Dissemination.Mailer, adapter: Bamboo.TestAdapter

config :recaptcha, http_client: Recaptcha.Http.MockClient

config :exvcr,
  vcr_cassette_library_dir: "test/fixture/vcr_cassettes",
  custom_cassette_library_dir: "test/fixture/custom_cassettes",
  filter_request_headers: ["x-api-key"]
