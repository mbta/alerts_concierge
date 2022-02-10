defmodule AlertProcessor.Reminders.Processor.SubscriptionsToRemindTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.Reminders.Processor.SubscriptionsToRemind
  alias AlertProcessor.Model.{Alert, Notification}

  describe "perform/1" do
    test "if reminder due" do
      monday_april_2_at_8am = ~U[2018-04-02 08:00:00Z]
      monday_april_9_at_7_30am = ~U[2018-04-09 07:30:00Z]
      monday_april_9_at_7_45am = ~U[2018-04-09 07:45:00Z]
      user = build(:user)

      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }

      subscription = build(:subscription, subscription_details)

      alert = %Alert{
        id: "123",
        last_push_notification: monday_april_2_at_8am,
        reminder_times: [monday_april_9_at_7_30am]
      }

      notification = %Notification{
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

      assert [subscription_to_remind] =
               SubscriptionsToRemind.perform({alert, [notification], monday_april_9_at_7_45am})

      assert subscription_to_remind.id == subscription.id
    end

    test "if a second reminder is due" do
      monday_april_2_at_8am = ~U[2018-04-02 08:00:00Z]
      tuesday_april_10_at_1pm = ~U[2018-04-10 13:00:00Z]
      monday_april_16_at_7_01am = ~U[2018-04-16 07:01:00Z]
      tuesday_april_17_at_1pm = ~U[2018-04-17 13:00:00Z]
      monday_april_23_at_7_01am = ~U[2018-04-23 07:01:00Z]
      user = build(:user)

      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }

      subscription = build(:subscription, subscription_details)

      alert = %Alert{
        id: "123",
        last_push_notification: monday_april_2_at_8am,
        reminder_times: [tuesday_april_10_at_1pm, tuesday_april_17_at_1pm]
      }

      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: monday_april_2_at_8am,
        subscriptions: [subscription],
        inserted_at: monday_april_16_at_7_01am
      }

      assert [subscription_to_remind] =
               SubscriptionsToRemind.perform({alert, [notification], monday_april_23_at_7_01am})

      assert subscription_to_remind.id == subscription.id
    end

    test "if reminder not due yet" do
      monday_april_2_at_8am = ~U[2018-04-02 08:00:00Z]
      monday_april_9_at_7_30am = ~U[2018-04-09 07:30:00Z]
      monday_april_16_at_7_30am = ~U[2018-04-16 07:30:00Z]
      user = build(:user)

      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }

      subscription = build(:subscription, subscription_details)

      alert = %Alert{
        id: "123",
        last_push_notification: monday_april_2_at_8am,
        reminder_times: [monday_april_16_at_7_30am]
      }

      notification = %Notification{
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

      assert [] = SubscriptionsToRemind.perform({alert, [notification], monday_april_9_at_7_30am})
    end

    test "if reminder not due yet and multiple reminder times" do
      monday_april_2_at_8am = ~U[2018-04-02 08:00:00Z]
      monday_april_9_at_7_30am = ~U[2018-04-09 07:30:00Z]
      monday_april_16_at_7_30am = ~U[2018-04-16 07:30:00Z]
      monday_april_23_at_7_30am = ~U[2018-04-23 07:30:00Z]
      user = build(:user)

      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }

      subscription = build(:subscription, subscription_details)

      alert = %Alert{
        id: "123",
        last_push_notification: monday_april_2_at_8am,
        reminder_times: [monday_april_9_at_7_30am, monday_april_23_at_7_30am]
      }

      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: monday_april_2_at_8am,
        subscriptions: [subscription],
        inserted_at: monday_april_9_at_7_30am
      }

      assert [] =
               SubscriptionsToRemind.perform({alert, [notification], monday_april_16_at_7_30am})
    end

    test "with two reminders that were already sent" do
      monday_april_2_at_8am = ~U[2018-04-02 08:00:00Z]
      monday_april_9_at_7_30am = ~U[2018-04-09 07:30:00Z]
      monday_april_16_at_7_30am = ~U[2018-04-16 07:30:00Z]
      monday_april_23_at_7_30am = ~U[2018-04-23 07:30:00Z]
      user = build(:user)

      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }

      subscription = build(:subscription, subscription_details)

      alert = %Alert{
        id: "123",
        last_push_notification: monday_april_2_at_8am,
        reminder_times: [monday_april_9_at_7_30am, monday_april_16_at_7_30am]
      }

      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: monday_april_2_at_8am,
        subscriptions: [subscription],
        inserted_at: monday_april_16_at_7_30am
      }

      # Note that the second argument is expected to include the latest known
      # sent notification for a user/alert combination.
      assert [] =
               SubscriptionsToRemind.perform({alert, [notification], monday_april_23_at_7_30am})
    end

    test "reminders are sent within notification window only" do
      monday_april_2_at_8am = ~U[2018-04-02 08:00:00Z]
      friday_april_6_at_1pm = ~U[2018-04-06 13:00:00Z]
      friday_april_6_at_2pm = ~U[2018-04-06 14:00:00Z]
      monday_april_9_at_6am = ~U[2018-04-09 06:00:00Z]
      monday_april_9_at_7_30am = ~U[2018-04-09 07:30:00Z]
      user = build(:user)

      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }

      subscription = build(:subscription, subscription_details)

      alert = %Alert{
        id: "123",
        last_push_notification: monday_april_2_at_8am,
        reminder_times: [friday_april_6_at_1pm]
      }

      notification = %Notification{
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

      assert [] = SubscriptionsToRemind.perform({alert, [notification], friday_april_6_at_2pm})
      assert [] = SubscriptionsToRemind.perform({alert, [notification], monday_april_9_at_6am})

      assert [returned_subscription] =
               SubscriptionsToRemind.perform({alert, [notification], monday_april_9_at_7_30am})

      assert returned_subscription.id == subscription.id
    end

    test "adds `:notification_type_to_send` of `:reminder` to returned subscriptions" do
      monday_april_2_at_8am = ~U[2018-04-02 08:00:00Z]
      monday_april_9_at_7_30am = ~U[2018-04-09 07:30:00Z]
      monday_april_9_at_7_45am = ~U[2018-04-09 07:45:00Z]
      user = build(:user)

      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }

      subscription = build(:subscription, subscription_details)

      alert = %Alert{
        id: "123",
        last_push_notification: monday_april_2_at_8am,
        reminder_times: [monday_april_9_at_7_30am]
      }

      notification = %Notification{
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

      assert [subscription_to_remind] =
               SubscriptionsToRemind.perform({alert, [notification], monday_april_9_at_7_45am})

      assert subscription_to_remind.id == subscription.id
      assert subscription_to_remind.notification_type_to_send == :reminder
    end
  end
end
