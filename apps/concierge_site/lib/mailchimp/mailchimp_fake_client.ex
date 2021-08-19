defmodule ConciergeSite.Mailchimp.FakeClient do
  @moduledoc "Fake version of `HTTPoison` used for testing `Mailchimp`."

  def put("/3.0/lists/abc123/members/0CF242BFA32139E06B25456DA90D29D1", data, _headers) do
    %{"email_address" => "error@example.com"} = Poison.decode!(data)
    {:error, %{status_code: 500}}
  end

  def put("/3.0/lists/abc123/members/" <> _, data, _headers) do
    %{"email_address" => _, "status" => _, "status_if_new" => _} = Poison.decode!(data)
    {:ok, %{status_code: 200}}
  end
end
