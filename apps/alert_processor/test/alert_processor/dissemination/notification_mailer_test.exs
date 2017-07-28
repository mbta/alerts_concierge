defmodule AlertProcessor.NotificationMailerTest do
  @moduledoc false
  use AlertProcessor.DataCase
  use Bamboo.Test
  import AlertProcessor.Factory
  alias AlertProcessor.{Model, NotificationMailer}
  alias Model.{Alert, InformedEntity, Notification}

  @alert %Alert{
    id: "1",
    informed_entities: [%InformedEntity{route_type: 1, route: "Red"}]
  }

  @email "test@test.com"

  @notification %Notification{
    user: build(:user),
    email: @email,
    service_effect: "Red line delay",
    header: "Red line inbound from Alewife station closure",
    description: "There is a fire in at south station so it is closed",
    alert: @alert
  }

  test "text_email/1 has all necessary content" do
    email = NotificationMailer.notification_email(@notification, "/unsubscribe/top_secret_token")
    body = email.text_body

    assert email.to == @email
    assert body =~ "Red line delay"
    assert body =~ "Red line inbound from Alewife station closure"
    assert body =~ "There is a fire in at south station so it is closed"
    assert body =~ "unsubscribe/top_secret_token"
 end

  test "html_email/1 has all content and link for alerts page" do
    email = NotificationMailer.notification_email(@notification, "/unsubscribe/top_secret_token")
    body = email.html_body

    assert email.to == @email
    assert body =~ "Red line delay"
    assert body =~ "Red line inbound from Alewife station closure"
    assert body =~ "href=\"https://t.mbta.com/\""
    assert body =~ "unsubscribe/top_secret_token"
  end
end
