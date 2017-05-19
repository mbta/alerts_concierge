defmodule AlertProcessor.DigestDispatcherTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  alias AlertProcessor.{DigestDispatcher, DigestMailer, Model}
  alias Model.{Alert, Digest, DigestMessage, User}

  test "send_email/1 sends emails from digest list" do
    user = %User{email: "abc@123.com"}
    alert = %Alert{id: "1", header: "Test"}
    digest = %Digest{user: user, alerts: [alert]}
    message = DigestMessage.from_digest(digest)

    DigestDispatcher.send_emails([message])
    assert_delivered_email DigestMailer.digest_email(message)
  end
end
