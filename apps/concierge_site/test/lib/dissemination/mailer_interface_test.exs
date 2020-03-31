defmodule ConciergeSite.Dissemination.MailerInterfaceTest do
  @moduledoc false
  use ConciergeSite.DataCase
  alias ConciergeSite.Dissemination.MailerInterface
  alias AlertProcessor.Model.{Alert, InformedEntity, Notification}

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

      {:reply, {:ok, {:delivered_email, sent_email}}, nil} =
        MailerInterface.handle_call({:send_notification_email, notification}, nil, nil)

      assert sent_email.to == [{nil, email}]
      assert sent_email.text_body =~ "Red line delay"
      assert sent_email.text_body =~ "Red line inbound from Alewife station closure"
      assert sent_email.text_body =~ "There is a fire at south station so it is closed"
    end
  end
end
