defmodule AlertProcessor.DigestDispatcherTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  alias AlertProcessor.{DigestDispatcher, DigestMailer, Model}
  alias Model.{Alert, Digest, User}

  test "send_email/1 sends emails from digest list" do
    user = %User{email: "abc@123.com"}
    alert = %Alert{id: "1", header: "Test"}
    digest = %Digest{user: user, alerts: [alert], serialized_alerts: ["Test"]}

    DigestDispatcher.send_emails([digest])
    assert_delivered_email DigestMailer.digest_email(digest)
  end
end
