{:ok, _} = Application.ensure_all_started(:ex_machina)
{:ok, _} = Application.ensure_all_started(:alert_processor)

ExUnit.configure(exclude: [pending: true])
ExUnit.start()
ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes", "test/fixture/custom_cassettes")

Ecto.Adapters.SQL.Sandbox.mode(AlertProcessor.Repo, :manual)

Application.put_env(:wallaby, :base_url, ConciergeSite.Endpoint.url)
{:ok, _} = Application.ensure_all_started(:wallaby)
