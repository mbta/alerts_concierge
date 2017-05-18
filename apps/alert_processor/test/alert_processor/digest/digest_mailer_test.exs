defmodule AlertProcessor.DigestMailerTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  alias AlertProcessor.{DigestMailer, Model}
  alias Model.{Alert, Digest, User}

  test "what" do
    user = %User{email: "abc@123.com"}
    alert = %Alert{id: "1", header: "Test"}
    digest = %Digest{user: user, alerts: [alert], serialized_alerts: ["Test"]}
    email = DigestMailer.digest_email(digest)

    assert email.to == user.email
    assert email.html_body == alert.header
  end
end
