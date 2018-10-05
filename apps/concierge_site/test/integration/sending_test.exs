defmodule ConciergeSite.Integration.Sending do
  @moduledoc false
  use ConciergeSite.ConnCase
  import AlertProcessor.SubscriptionFilterEngine, only: [schedule_all_notifications: 2]
  alias AlertProcessor.Model.{Alert, InformedEntity}
  alias ConciergeSite.Dissemination.MailerInterface
  alias AlertProcessor.{SendingQueue, NotificationSmser}

  describe "subway subscription" do
    @alert %Alert{
      active_period: [
        %{
          end: DateTime.from_naive!(~N[2018-01-02 08:30:00], "Etc/UTC"),
          start: DateTime.from_naive!(~N[2018-01-02 08:00:00], "Etc/UTC")
        }
      ],
      created_at: DateTime.from_naive!(~N[2018-01-01 05:00:00], "Etc/UTC"),
      effect_name: "Service Change",
      header: "Header Text",
      id: "1",
      informed_entities: [
        %InformedEntity{
          activities: ["BOARD"],
          direction_id: 0,
          route: "Red",
          route_type: 1,
          stop: "place-harsq"
        }
      ],
      last_push_notification: DateTime.from_naive!(~N[2018-01-01 05:00:00], "Etc/UTC"),
      service_effect: "Service Effect"
    }

    @subscription %{
      direction_id: 0,
      start_time: ~T[08:00:00],
      end_time: ~T[08:30:00],
      type: :subway,
      relevant_days: [:monday, :tuesday, :wednesday, :thursday, :friday],
      origin: "place-harsq",
      destination: "place-brdwy",
      route: "Red",
      route_type: 1
    }

    test "email" do
      user = insert(:user)
      insert(:subscription, Map.put(@subscription, :user_id, user.id))
      schedule_all_notifications([@alert], :anytime)
      {:ok, notification} = SendingQueue.pop()

      {:reply, sent_email, nil} =
        MailerInterface.handle_call({:send_notification_email, notification}, nil, nil)

      assert sent_email.to == [{nil, user.email}]
    end

    test "sms" do
      user = insert(:user, %{phone_number: "5556667777"})
      insert(:subscription, Map.put(@subscription, :user_id, user.id))
      schedule_all_notifications([@alert], :anytime)
      {:ok, notification} = SendingQueue.pop()
      sms_operation = NotificationSmser.notification_sms(notification)
      assert sms_operation.params["PhoneNumber"] == "+1#{user.phone_number}"
    end
  end
end
