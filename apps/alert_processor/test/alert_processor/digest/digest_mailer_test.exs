defmodule AlertProcessor.DigestMailerTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: false
  use Bamboo.Test, shared: true

  alias AlertProcessor.{DigestMailer, Model}
  alias Model.{Alert, Digest, DigestDateGroup, DigestMessage, InformedEntity, User}
  alias Calendar.DateTime, as: DT

  @now Calendar.DateTime.now!("America/New_York")
  @saturday DT.from_erl!({{2017, 05, 26}, {0, 0, 0}}, "America/New_York")
  @end_sunday DT.from_erl!({{2017, 05, 27}, {23, 59, 59}}, "America/New_York")

  @ddg %DigestDateGroup{
    upcoming_weekend: %{
      timeframe: {@saturday, @end_sunday},
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

  @alert %Alert{
    id: "1",
    header: "This is a Test",
    service_effect: "Service Effect",
    informed_entities: [%InformedEntity{route_type: 1, route: "Red"}]
  }

  test "text_email/1 has all content and link for alerts page" do
    user = %User{email: "abc@123.com"}
    digest = %Digest{user: user, alerts: [@alert], digest_date_group: @ddg}
    message = DigestMessage.from_digest(digest)
    email = DigestMailer.digest_email(message, "/unsubscribe/top_secret_token")
    body = email.text_body

    assert email.to == user.email
    assert body =~ "This is a Test"
    assert body =~ "Service Effect"
    assert body =~ "https://t.mbta.com/"
    assert body =~ "This Weekend, May 26 - 27"
    assert body =~ "unsubscribe/top_secret_token"
 end

  test "html_email/1 has all content and link for alerts page" do
    user = %User{email: "abc@123.com"}
    digest = %Digest{user: user, alerts: [@alert], digest_date_group: @ddg}
    message = DigestMessage.from_digest(digest)
    email = DigestMailer.digest_email(message, "/unsubscribe/top_secret_token")
    body = email.html_body

    assert email.to == user.email
    assert body =~ "This is a Test"
    assert body =~ "Service Effect"
    assert body =~ "href=\"https://t.mbta.com/\""
    assert body =~ "This Weekend, May 26 - 27"
    assert body =~ "unsubscribe/top_secret_token"
  end
end
