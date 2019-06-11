defmodule ConciergeSite.MailchimpTest do
  @moduledoc false
  use ExUnit.Case

  alias AlertProcessor.Model.User
  alias ConciergeSite.Mailchimp

  describe "add_member/3" do
    test "success subscribe" do
      user = %User{email: "success@test.com", id: "abc123", digest_opt_in: true}
      assert :ok == Mailchimp.add_member(user)
    end

    test "success ignore" do
      user = %User{email: "ignore@test.com", id: "abc123", digest_opt_in: false}
      assert :ok == Mailchimp.add_member(user)
    end

    test "error" do
      user = %User{email: "error@test.com", id: "abc123", digest_opt_in: true}
      assert :error == Mailchimp.add_member(user)
    end
  end

  describe "send_member_status_update/2" do
    test "success" do
      user = %User{email: "success@test.com", id: "abc123", digest_opt_in: true}
      assert :ok == Mailchimp.send_member_status_update(user)
    end

    test "error" do
      user = %User{email: "error@test.com", id: "abc123", digest_opt_in: true}
      assert :error == Mailchimp.send_member_status_update(user)
    end
  end
end
