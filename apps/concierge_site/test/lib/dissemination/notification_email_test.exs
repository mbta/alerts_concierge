defmodule ConciergeSite.Dissemination.NotificationEmailTest do
  @moduledoc false
  use ConciergeSite.DataCase
  use Bamboo.Test, shared: true
  alias ConciergeSite.Dissemination.NotificationEmail
  alias AlertProcessor.Model.{Alert, InformedEntity, Notification}

  @alert %Alert{
    id: "1",
    informed_entities: [%InformedEntity{route_type: 1, route: "Red"}]
  }

  @email "test@test.com"

  @notification %Notification{
    user: build(:user, email: @email),
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

  test "email_subject/1 with timeframe and recurrence" do
    alert = %{@alert | timeframe: "starting September 1", recurrence: "on weekends"}
    notification = %{@notification | alert: alert}
    subject = NotificationEmail.email_subject(notification)

    assert IO.iodata_to_binary(subject) == "Starting September 1: Red line delay on weekends"
  end

  test "email_subject/1 with recurrence" do
     alert = %{@alert | recurrence: "Monday-Tuesday"}
    notification = %{@notification | alert: alert}
    subject = NotificationEmail.email_subject(notification)

    assert IO.iodata_to_binary(subject) == "Red line delay Monday-Tuesday"
  end

  test "email_subject/1 with timeframe" do
    alert = %{@alert | timeframe: "starting Monday"}
    notification = %{@notification | alert: alert}
    subject = NotificationEmail.email_subject(notification)

    assert IO.iodata_to_binary(subject) == "Starting Monday: Red line delay"
  end

  test "email_subject/1 without timeframe or recurrence" do
    subject = NotificationEmail.email_subject(@notification)
    assert IO.iodata_to_binary(subject) == "Red line delay"
  end
end
