Application.put_env(:wallaby, :base_url, ConciergeSite.Endpoint.url())
ExUnit.start()
