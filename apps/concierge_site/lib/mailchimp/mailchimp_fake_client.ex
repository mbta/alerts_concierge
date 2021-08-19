defmodule ConciergeSite.Mailchimp.FakeClient do
  @moduledoc "Fake version of `HTTPoison` used for testing `Mailchimp`."

  def put("/3.0/lists/abc123/members/0CF242BFA32139E06B25456DA90D29D1", data, _headers) do
    %{"email_address" => "error@example.com"} = Poison.decode!(data)
    {:error, %{status_code: 500}}
  end

  def put("/3.0/lists/abc123/members/" <> <<_::binary-size(32)>>, data, _headers) do
    %{"email_address" => _, "status" => _, "status_if_new" => _} = Poison.decode!(data)
    {:ok, %{status_code: 200}}
  end

  def post(
        "/3.0/lists/abc123/members/0CF242BFA32139E06B25456DA90D29D1/actions/delete-permanent",
        _data,
        _headers
      ) do
    {:error, %{status_code: 500}}
  end

  def post(
        "/3.0/lists/abc123/members/" <> <<_::binary-size(32)>> <> "/actions/delete-permanent",
        _data,
        _headers
      ) do
    {:ok, %{status_code: 204}}
  end
end
