defmodule ConciergeSite.MailchimpTest do
  @moduledoc false
  use ExUnit.Case

  alias AlertProcessor.Model.User
  alias ConciergeSite.Mailchimp
  import ExUnit.CaptureLog

  describe "update_member/1" do
    test "success" do
      user = %User{email: "success@example.com", digest_opt_in: true}

      assert :ok == Mailchimp.update_member(user)
    end

    test "error" do
      user = %User{id: "fakeid", email: "error@example.com", digest_opt_in: true}

      logs = capture_log(fn -> assert :error == Mailchimp.update_member(user) end)

      assert logs =~ "Mailchimp event=update_failed user_id=fakeid"
    end
  end
end
