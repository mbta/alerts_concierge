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
    id: "a7722510-6a27-44ee-808e-b242312abb6d",
    user: build(:user, email: @email),
    email: @email,
    service_effect: "Red line delay",
    header: "Red line inbound from Alewife station closure",
    description: "There is a fire in at south station so it is closed",
    url: "http://www.example.com/alert-info",
    alert: @alert,
    last_push_notification: %DateTime{
      year: 2017,
      month: 1,
      day: 18,
      zone_abbr: "UTC",
      hour: 19,
      minute: 0,
      second: 0,
      microsecond: {0, 0},
      utc_offset: 0,
      std_offset: 0,
      time_zone: "Etc/UTC"
    },
    closed_timestamp: nil,
    alert_id: "123",
    user_id: "456"
  }

  test "text_email/1 has all necessary content" do
    email = NotificationEmail.notification_email(@notification)
    body = email.text_body

    assert email.to == @email
    assert body =~ "Red line delay"
    assert body =~ "Red line inbound from Alewife station closure"
    assert body =~ "There is a fire in at south station so it is closed"
    assert body =~ "Last Updated: Jan 18 2017 02:00 PM"
  end

  test "text_email/1 includes content for closed alerts" do
    notification = %{
      @notification
      | closed_timestamp: DateTime.utc_now(),
        type: :all_clear
    }

    email = NotificationEmail.notification_email(notification)
    body = email.text_body

    assert email.to == @email
    assert body =~ "All clear (re: Red line delay)"
    assert body =~ "The issue described below has ended:"
    assert body =~ "  Red line inbound from Alewife station closure"
  end

  test "html_email/1 has all content and link for alerts page" do
    email = NotificationEmail.notification_email(@notification)
    body = email.html_body

    assert email.to == @email
    assert body =~ "Red line inbound from Alewife station closure"
    assert body =~ "href=\"https://www.mbta.com/alerts\""
    assert body =~ "Last Updated: Jan 18 2017 02:00 PM"
    assert body =~ "feedback?alert_id=123&user_id=456&rating=yes"
    assert body =~ "feedback?alert_id=123&user_id=456&rating=no"

    assert body =~
             "notification_email_opened?alert_id=123&notification_id=a7722510-6a27-44ee-808e-b242312abb6d"
  end

  test "html_email/1 includes content for closed alerts" do
    notification = %{
      @notification
      | closed_timestamp: DateTime.utc_now(),
        type: :all_clear
    }

    email = NotificationEmail.notification_email(notification)
    body = email.html_body

    assert email.to == @email
    assert body =~ "The issue described below has ended:"
    assert body =~ "Red line inbound from Alewife station closure"
  end

  describe "email_subject/1" do
    test "with timeframe and recurrence" do
      alert = %{@alert | timeframe: "starting September 1", recurrence: "on weekends"}
      notification = %{@notification | alert: alert}
      subject = NotificationEmail.email_subject(notification)

      assert subject == "Starting September 1: Red line delay on weekends"
    end

    test "with recurrence" do
      alert = %{@alert | recurrence: "Monday-Tuesday"}
      notification = %{@notification | alert: alert}
      subject = NotificationEmail.email_subject(notification)

      assert subject == "Red line delay Monday-Tuesday"
    end

    test "with timeframe" do
      alert = %{@alert | timeframe: "starting Monday"}
      notification = %{@notification | alert: alert}
      subject = NotificationEmail.email_subject(notification)

      assert subject == "Starting Monday: Red line delay"
    end

    test "without timeframe or recurrence" do
      subject = NotificationEmail.email_subject(@notification)
      assert subject == "Red line delay"
    end

    test "closed alert" do
      alert = %{@alert | timeframe: "starting September 1", recurrence: "on weekends"}

      notification = %{
        @notification
        | alert: alert,
          closed_timestamp: DateTime.utc_now(),
          type: :all_clear
      }

      subject = NotificationEmail.email_subject(notification)

      assert subject == "All clear (re: Starting September 1: Red line delay on weekends)"
    end

    test "updated alert" do
      alert = %{@alert | timeframe: "starting September 1", recurrence: "on weekends"}

      notification = %{
        @notification
        | alert: alert,
          closed_timestamp: DateTime.utc_now(),
          type: :update
      }

      subject = NotificationEmail.email_subject(notification)

      assert subject == "Update (re: Starting September 1: Red line delay on weekends)"
    end

    test "reminder alert" do
      alert = %{@alert | timeframe: "starting September 1", recurrence: "on weekends"}

      notification = %{
        @notification
        | alert: alert,
          closed_timestamp: DateTime.utc_now(),
          type: :reminder
      }

      subject = NotificationEmail.email_subject(notification)

      assert subject == "Reminder (re: Starting September 1: Red line delay on weekends)"
    end
  end
end
