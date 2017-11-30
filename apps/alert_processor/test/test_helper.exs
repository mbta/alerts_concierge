{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.configure(exclude: [pending: true])
ExUnit.start()
ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes", "test/fixture/custom_cassettes")
ExVCR.Config.filter_request_headers("x-api-key")

Ecto.Adapters.SQL.Sandbox.mode(AlertProcessor.Repo, :manual)
