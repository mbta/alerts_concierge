defmodule AlertProcessor.DigestSerializerTest do
  use ExUnit.Case

  alias AlertProcessor.{Model, DigestSerializer}
  alias Model.{Alert, Digest, User}

  @user %User{email: "abc@123.com"}
  @thursday Calendar.DateTime.from_erl!({{2017, 05, 25}, {0, 0, 0}}, "America/New_York")

  test "serialize/1 generates data structured for email in DigestMessage body" do
    alert = %Alert{id: "1", header: "Test", digest_groups: [:upcoming_weekend]}
    digest = %Digest{user: @user, alerts: [alert]}
    message = DigestSerializer.serialize(digest, @thursday)

    assert [{header, [email_alert]}] = message
    assert email_alert.id == alert.id
    assert header =~ "This Weekend, May 27 - 28"
 end

 test "serialize/1 works across month boundary" do
    alert = %Alert{id: "1", header: "Test", digest_groups: [:upcoming_week]}
    digest = %Digest{user: @user, alerts: [alert]}
    message = DigestSerializer.serialize(digest, @thursday)

    assert [{header, _}] = message
    assert header =~ "Next Week, May 29 - June 2"
 end
end
