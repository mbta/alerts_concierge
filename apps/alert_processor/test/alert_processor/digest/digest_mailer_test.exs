defmodule AlertProcessor.DigestMailerTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  alias AlertProcessor.{DigestMailer, Model}
  alias Model.{Alert, Digest, DigestDateGroup, DigestMessage, User}

  @now Calendar.DateTime.now!("America/New_York")
  @ddg %DigestDateGroup{
    upcoming_weekend: %{
      timeframe: {@now, @now},
      alert_ids: ["1"]
    },
    upcoming_week: %{
      timeframe: {@now, @now},
      alert_ids: ["1"]
    },
    next_weekend: %{
      timeframe: {@now, @now},
      alert_ids: ["1"]
    },
    future: %{
      timeframe: {@now, @now},
      alert_ids: ["1"]
    }
  }

  test "what" do
    user = %User{email: "abc@123.com"}
    alert = %Alert{id: "1", header: "Test"}
    digest = %Digest{user: user, alerts: [alert], digest_date_group: @ddg}
    message = DigestMessage.from_digest(digest)
    email = DigestMailer.digest_email(message)
    assert email.to == user.email
    # TODO
 end
end
