defmodule AlertProcessor.DigestMailerTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  alias AlertProcessor.{DigestMailer, Model}
  alias Model.{Alert, Digest, DigestMessage, User}

  test "digest_email" do
    user = %User{email: "abc@123.com"}
    alert = %Alert{id: "1", header: "Test", digest_groups: [:upcoming_week]}
    digest = %Digest{user: user, alerts: [alert]}
    message = DigestMessage.from_digest(digest)
    email = DigestMailer.digest_email(message)

    # Update once email formatting complete
    assert [{
      _header,
      [_email_alert]
    }] = email.html_body

    assert email.to == user.email
  end
end
