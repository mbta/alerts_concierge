defmodule AlertProcessor.Reminders.ProcessorTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Reminders.Processor
  alias AlertProcessor.Model.{Alert, Notification}
  alias AlertProcessor.SendingQueue

  setup do
    SendingQueue.reset()
  end

  describe "process_alerts/2" do
    test "if reminder due" do
      monday_april_2_at_8am = ~U[2018-04-02 08:00:00Z]
      monday_april_9_at_7_30am = ~U[2018-04-09 07:30:00Z]
      monday_april_9_at_7_45am = ~U[2018-04-09 07:45:00Z]
      user = insert(:user)

      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }

      subscription = insert(:subscription, subscription_details)

      alert = %Alert{
        id: "123",
        last_push_notification: monday_april_2_at_8am,
        reminder_times: [monday_april_9_at_7_30am],
        header: "test",
        service_effect: "test"
      }

      notification_details = %{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: monday_april_2_at_8am,
        subscriptions: [subscription],
        inserted_at: monday_april_2_at_8am
      }

      notification = insert(:notification, notification_details)
      insert(:notification_subscription, notification: notification, subscription: subscription)

      Processor.process_alerts([alert], monday_april_9_at_7_45am)

      assert {:ok, notification} = SendingQueue.pop()

      [target_subscription_id] =
        Enum.map(notification.notification_subscriptions, & &1.subscription_id)

      assert target_subscription_id == subscription.id
      # SendingQueue.pop/0 returns :error when empty
      assert :error = SendingQueue.pop()
    end

    test "if reminder not due yet" do
      monday_april_2_at_8am = ~U[2018-04-02 08:00:00Z]
      monday_april_9_at_7_30am = ~U[2018-04-09 07:30:00Z]
      monday_april_16_at_7_30am = ~U[2018-04-16 07:30:00Z]
      user = insert(:user)

      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }

      subscription = insert(:subscription, subscription_details)

      alert = %Alert{
        id: "123",
        last_push_notification: monday_april_2_at_8am,
        reminder_times: [monday_april_16_at_7_30am]
      }

      notification_details = %{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: monday_april_2_at_8am,
        subscriptions: [subscription],
        inserted_at: monday_april_2_at_8am
      }

      notification = insert(:notification, notification_details)
      insert(:notification_subscription, notification: notification, subscription: subscription)

      Processor.process_alerts([alert], monday_april_9_at_7_30am)

      # SendingQueue.pop/0 returns :error when empty
      assert :error = SendingQueue.pop()
    end

    test "reminder is only sent once for a timeframe, even if push_notification is updated" do
      monday_april_2_at_8am = ~U[2018-04-02 08:00:00Z]
      monday_april_9_at_7_30am = ~U[2018-04-09 07:30:00Z]
      monday_april_9_at_7_45am = ~U[2018-04-09 07:45:00Z]
      monday_april_9_at_7_55am = ~U[2018-04-09 07:55:00Z]
      user = insert(:user)

      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }

      subscription = insert(:subscription, subscription_details)

      alert = %Alert{
        id: "123",
        last_push_notification: monday_april_2_at_8am,
        reminder_times: [monday_april_9_at_7_30am],
        header: "test",
        service_effect: "test"
      }

      notification_details = %{
        id: Ecto.UUID.generate(),
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: monday_april_2_at_8am,
        subscriptions: [subscription],
        inserted_at: monday_april_2_at_8am
      }

      notification = insert(:notification, notification_details)
      insert(:notification_subscription, notification: notification, subscription: subscription)

      Processor.process_alerts([alert], monday_april_9_at_7_45am)

      assert {:ok, notification_to_send} = SendingQueue.pop()

      [target_subscription_id] =
        Enum.map(notification_to_send.notification_subscriptions, & &1.subscription_id)

      assert target_subscription_id == subscription.id
      # SendingQueue.pop/0 returns :error when empty
      assert :error = SendingQueue.pop()

      notification
      |> Notification.create_changeset(%{last_push_notification: monday_april_9_at_7_55am})
      |> Repo.update()

      Processor.process_alerts([alert], monday_april_9_at_7_55am)

      # SendingQueue.pop/0 returns :error when empty
      assert :error = SendingQueue.pop()
    end
  end
end
