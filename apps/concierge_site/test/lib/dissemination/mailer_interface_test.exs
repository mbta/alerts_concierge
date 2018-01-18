defmodule ConciergeSite.Dissemination.MailerInterfaceTest do
  use ConciergeSite.DataCase
  alias ConciergeSite.Dissemination.MailerInterface
  alias AlertProcessor.Model.{Alert, Digest, DigestDateGroup, DigestMessage, InformedEntity, Notification, User}

  describe "send_notification_email" do
    test "receives a notification and sends an email" do
      alert = %Alert{
        id: "1",
        informed_entities: [%InformedEntity{route_type: 1, route: "Red"}]
      }

      email = "test@test.com"

      notification = %Notification{
        user: build(:user, email: email),
        email: email,
        service_effect: "Red line delay",
        header: "Red line inbound from Alewife station closure",
        description: "There is a fire at south station so it is closed",
        alert: alert
      }
      {:reply, sent_email, nil} = MailerInterface.handle_call({:send_notification_email, notification}, nil, nil)
      assert sent_email.to == [{nil, email}]
      assert sent_email.text_body =~ "Red line delay"
      assert sent_email.text_body =~ "Red line inbound from Alewife station closure"
      assert sent_email.text_body =~ "There is a fire at south station so it is closed"
    end
  end

  describe "send_digest_email" do
    test "receives a digest message and sends an email" do
      now = Calendar.DateTime.now!("America/New_York")
      saturday = Calendar.DateTime.from_erl!({{2017, 05, 26}, {0, 0, 0}}, "America/New_York")
      end_sunday = Calendar.DateTime.from_erl!({{2017, 05, 28}, {02, 30, 00}}, "America/New_York")

      digest_date_group = %DigestDateGroup{
        upcoming_weekend: %{
          timeframe: {saturday, end_sunday},
          alert_ids: ["1"]
        },
        upcoming_week: %{
          timeframe: {now, now},
          alert_ids: ["1"]
        },
        next_weekend: %{
          timeframe: {now, now},
          alert_ids: ["1"]
        },
        future: %{
          timeframe: {now, now},
          alert_ids: ["1"]
        }
      }
      alert = %Alert{
        id: "1",
        header: "This is a Test",
        service_effect: "Service Effect",
        informed_entities: [%InformedEntity{route_type: 1, route: "Red"}]
      }
      user = %User{email: "abc@123.com"}
      digest = %Digest{user: user, alerts: [alert], digest_date_group: digest_date_group}
      message = DigestMessage.from_digest(digest)

      {:reply, sent_email, nil} = MailerInterface.handle_call({:send_digest_email, message}, nil, nil)
      assert sent_email.to == [{nil, user.email}]
      assert sent_email.text_body =~ "This is a Test"
      assert sent_email.text_body =~ "Service Effect"
      assert sent_email.text_body =~ "https://www.mbta.com/"
      assert sent_email.text_body =~ "This Weekend, May 26 - 27"
    end
  end
end
