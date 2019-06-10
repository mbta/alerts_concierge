defmodule ConciergeSite.Mailchimp.FakeClient do
  @moduledoc """
  module used in testing mailchimp
  """

  def post(_endpoint, data, _headers) do
    data = Poison.decode!(data)

    if data["email_address"] == "success@test.com" do
      {:ok, %{status_code: 200}}
    else
      {:error, %{status_code: 500}}
    end
  end

  def patch(endpoint, _data, _headers) do
    if endpoint ==
         "/3.0/lists/abc123/members/DC0C46B79F1514132B01F751B9B8AA54" do
      {:ok, %{status_code: 200}}
    else
      {:error, %{status_code: 500}}
    end
  end
end
