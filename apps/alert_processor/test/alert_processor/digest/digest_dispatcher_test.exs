defmodule AlertProcessor.DigestDispatcherTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  alias AlertProcessor.{DigestDispatcher, DigestMailer, Model}
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

  test "send_email/1 sends emails from digest list" do
    user = %User{email: "abc@123.com"}
    alert = %Alert{id: "1",
                   header: "Test",
                   informed_entities: [%{route_type: 1, route: "Red"}]}
    digest = %Digest{user: user, alerts: [alert], digest_date_group: @ddg}
    message = DigestMessage.from_digest(digest)

    DigestDispatcher.send_emails([message])
    assert_delivered_email DigestMailer.digest_email(message)
  end
end
