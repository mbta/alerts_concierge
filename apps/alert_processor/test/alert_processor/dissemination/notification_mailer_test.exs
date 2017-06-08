defmodule AlertProcessor.NotificationMailerTest do
  @moduledoc false
  use ExUnit.Case, async: false
  use Bamboo.Test, shared: true

  alias AlertProcessor.{Model, NotificationMailer}
  alias Model.{Alert, InformedEntity, Notification}

  @alert %Alert{
    id: "1",
    informed_entities: [%InformedEntity{route_type: 1, route: "Red"}]
  }

  @notification %Notification{
    service_effect: "Red line delay",
    header: "Red line inbound from Alewife station closure",
    description: "There is a fire in at south station so it is closed",
    alert: @alert
  }

  @email "test@test.com"

  test "text_email/1 has all necessary content" do
    email = NotificationMailer.notification_email(@notification, @email)
    body = email.text_body

    assert email.to == @email
    assert body =~ "Red line delay"
    assert body =~ "Red line inbound from Alewife station closure"
    assert body =~ "There is a fire in at south station so it is closed"
 end

  test "html_email/1 has all content and link for alerts page" do
    email = NotificationMailer.notification_email(@notification, @email)
    body = email.html_body

    assert email.to == @email
    assert body =~ "Red line delay"
    assert body =~ "Red line inbound from Alewife station closure"
    assert body =~ "href=\"https://t.mbta.com/\""
  end
end
