defmodule ConciergeSite.Integration.Sending do
  @moduledoc false
  use ConciergeSite.ConnCase
  use Bamboo.Test
  import AlertProcessor.SubscriptionFilterEngine, only: [schedule_all_notifications: 2]
  alias AlertProcessor.Model.{Alert, InformedEntity}
  alias AlertProcessor.Dissemination.NotificationSender
  alias AlertProcessor.SendingQueue

  describe "subway subscription" do
    @alert %Alert{
      active_period: [
        %{
          end: ~U[2018-01-02 08:30:00Z],
          start: ~U[2018-01-02 08:00:00Z]
        }
      ],
      created_at: ~U[2018-01-01 05:00:00Z],
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
      last_push_notification: ~U[2018-01-01 05:00:00Z],
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
      %{email: email, id: user_id} =
        insert(:user, %{communication_mode: "email", phone_number: nil})

      insert(:subscription, Map.put(@subscription, :user_id, user_id))
      schedule_all_notifications([@alert], :anytime)
      {:ok, notification} = SendingQueue.pop()
      NotificationSender.send(notification)

      assert_receive {:sent_email, %{to: ^email, notification: ^notification}}
    end

    test "SMS" do
      user = insert(:user, %{communication_mode: "sms", phone_number: "5556667777"})
      insert(:subscription, Map.put(@subscription, :user_id, user.id))
      schedule_all_notifications([@alert], :anytime)
      {:ok, notification} = SendingQueue.pop()
      NotificationSender.send(notification)

      assert_receive {:publish, %{"PhoneNumber" => "+15556667777"}}
    end
  end
end
