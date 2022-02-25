Application.put_env(:wallaby, :base_url, ConciergeSite.Endpoint.url())
{:ok, _} = Application.ensure_all_started(:wallaby)
ExUnit.start()
