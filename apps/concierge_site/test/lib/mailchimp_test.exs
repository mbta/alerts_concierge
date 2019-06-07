defmodule ConciergeSite.MailchimpTest do
  @moduledoc false
  use ExUnit.Case

  alias AlertProcessor.Model.User
  alias ConciergeSite.Mailchimp

  defmodule TestClient do
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
           "https://us20.api.mailchimp.com/3.0/lists/815915263a/members/DC0C46B79F1514132B01F751B9B8AA54" do
        {:ok, %{status_code: 200}}
      else
        {:error, %{status_code: 500}}
      end
    end
  end

  describe "add_member/3" do
    test "success subscribe" do
      user = %User{email: "success@test.com", id: "abc123", digest_opt_in: true}
      assert :ok == Mailchimp.add_member(user, client: TestClient)
    end

    test "success ignore" do
      user = %User{email: "ignore@test.com", id: "abc123", digest_opt_in: false}
      assert :ok == Mailchimp.add_member(user, client: TestClient)
    end

    test "error" do
      user = %User{email: "error@test.com", id: "abc123", digest_opt_in: true}
      assert :error == Mailchimp.add_member(user, client: TestClient)
    end
  end

  describe "send_member_status_update/2" do
    test "success" do
      user = %User{email: "success@test.com", id: "abc123", digest_opt_in: true}
      assert :ok == Mailchimp.send_member_status_update(user, client: TestClient)
    end

    test "error" do
      user = %User{email: "error@test.com", id: "abc123", digest_opt_in: true}
      assert :error == Mailchimp.send_member_status_update(user, client: TestClient)
    end
  end
end
