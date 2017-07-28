defmodule AlertProcessor.DigestDispatcherTest do
  @moduledoc false
  use AlertProcessor.DataCase
  use Bamboo.Test, shared: true

  alias AlertProcessor.{DigestDispatcher, Model}
  alias Model.{Alert, Digest, DigestDateGroup, DigestMessage, InformedEntity, User}

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
                   informed_entities: [%InformedEntity{route_type: 1, route: "Red"}]}
    digest = %Digest{user: user, alerts: [alert], digest_date_group: @ddg}
    message = DigestMessage.from_digest(digest)

    DigestDispatcher.send_emails([message])
    assert_delivered_with(subject: "MBTA Alerts Digest")
  end
end
