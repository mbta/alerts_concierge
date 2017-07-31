defmodule ConciergeSite.Dissemination.NotificationEmailTest do
  @moduledoc false
  use ConciergeSite.ConnCase
  use Bamboo.Test, shared: true
  import AlertProcessor.Factory
  alias ConciergeSite.Dissemination.NotificationEmail
  alias AlertProcessor.Model.{Alert, InformedEntity, Notification}

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
    email = NotificationEmail.notification_email(@notification)
    body = email.text_body

    assert email.to == @email
    assert body =~ "Red line delay"
    assert body =~ "Red line inbound from Alewife station closure"
    assert body =~ "There is a fire in at south station so it is closed"
 end

  test "html_email/1 has all content and link for alerts page" do
    email = NotificationEmail.notification_email(@notification)
    body = email.html_body

    assert email.to == @email
    assert body =~ "Red line delay"
    assert body =~ "Red line inbound from Alewife station closure"
    assert body =~ "href=\"https://t.mbta.com/\""
  end
end
