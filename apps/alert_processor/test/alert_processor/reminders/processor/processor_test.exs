defmodule AlertProcessor.Reminders.ProcessorTest do
  use AlertProcessor.DataCase
  use Bamboo.Test
  import AlertProcessor.Factory
  alias AlertProcessor.Reminders.Processor
  alias AlertProcessor.Model.Alert
  alias AlertProcessor.SendingQueue

  setup do
    :ok = SendingQueue.reset()
    :ok
  end

  describe "process_alerts/2" do
    test "if reminder due" do
      monday_april_2_at_8am = DateTime.from_naive!(~N[2018-04-02 08:00:00], "Etc/UTC")
      monday_april_9_at_7_30am = DateTime.from_naive!(~N[2018-04-09 07:30:00], "Etc/UTC")
      monday_april_9_at_7_45am = DateTime.from_naive!(~N[2018-04-09 07:45:00], "Etc/UTC")
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
        reminder_times: [monday_april_9_at_7_30am]
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
        inserted_at: DateTime.to_naive(monday_april_2_at_8am),
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
      monday_april_2_at_8am = DateTime.from_naive!(~N[2018-04-02 08:00:00], "Etc/UTC")
      monday_april_9_at_7_30am = DateTime.from_naive!(~N[2018-04-09 07:30:00], "Etc/UTC")
      monday_april_16_at_7_30am = DateTime.from_naive!(~N[2018-04-16 07:30:00], "Etc/UTC")
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
        inserted_at: DateTime.to_naive(monday_april_2_at_8am),
      }
      notification = insert(:notification, notification_details)
      insert(:notification_subscription, notification: notification, subscription: subscription)

      Processor.process_alerts([alert], monday_april_9_at_7_30am)

      # SendingQueue.pop/0 returns :error when empty
      assert :error = SendingQueue.pop()
    end
  end
end