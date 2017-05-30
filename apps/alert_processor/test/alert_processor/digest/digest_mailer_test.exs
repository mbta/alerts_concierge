defmodule AlertProcessor.DigestMailerTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  alias AlertProcessor.{DigestMailer, Model}
  alias Model.{Alert, Digest, DigestMessage, User}

  test "what" do
    user = %User{email: "abc@123.com"}
    alert = %Alert{id: "1", header: "Test"}
    digest = %Digest{user: user, alerts: [alert]}
    message = DigestMessage.from_digest(digest)
    email = DigestMailer.digest_email(message)
    assert email.to == user.email
    assert email.html_body == alert.header
  end
end
