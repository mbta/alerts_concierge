defmodule AlertProcessor.SentAlertFilterTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.{SentAlertFilter, Model}
  alias Model.{Alert, Notification, NotificationSubscription, Subscription}
  import AlertProcessor.Factory

  @monday_at_7am DateTime.from_naive!(~N[2018-04-02 07:00:00], "Etc/UTC")
  @monday_at_8am DateTime.from_naive!(~N[2018-04-02 08:00:00], "Etc/UTC")
  @alert %Alert{id: "123", last_push_notification: @monday_at_7am}

  describe "filter/2" do
    test "returns all subscriptions that have not received the alert" do
      notified_user = insert(:user)
      sub1 = :subscription |> insert(user: notified_user) |> Repo.preload(:user)
      other_notification_user = insert(:user)
      sub2 = :subscription |> insert(user: other_notification_user) |> Repo.preload(:user)

      notification = %Notification{
        alert_id: "123",
        user_id: notified_user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: @monday_at_8am,
        subscriptions: [sub1]
      }

      other_notification = %Notification{
        alert_id: "456",
        user_id: other_notification_user.id,
        email: "c@d.com",
        header: "You have been notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: @monday_at_8am,
        subscriptions: [sub2]
      }

      n1 = Repo.insert!(Notification.create_changeset(notification))
      n2 = Repo.insert!(Notification.create_changeset(other_notification))

      assert {[sub2],  []} ==
        SentAlertFilter.filter([sub1, sub2], @alert, [n1, n2])
    end

    test "returns empty list if no match" do
      assert {[], []} = SentAlertFilter.filter([], @alert, [])
    end

    test "returns the subscription if notification failed" do
      user = insert(:user)
      subscription = insert(:subscription, user: user)

      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :failed,
        subscriptions: []
      }

      Repo.insert(Notification.create_changeset(notification))
      subscriptions =
        Subscription
        |> Repo.all()
        |> Repo.preload(:user)
        |> Repo.preload(:informed_entities)

      assert {[returned_sub], []} =
        SentAlertFilter.filter(subscriptions, @alert, [notification], @monday_at_8am)
      assert returned_sub.id == subscription.id
    end

    test "returns subscriptions to auto resend that have received the alert if the last_push_notification changed" do
      user = insert(:user)
      subscription_details = %{
        user: user,
        start_time: @monday_at_7am,
        end_time: @monday_at_8am,
        relevant_days: [:monday]
      }
      sub1 = insert(:subscription, subscription_details)
      :subscription |> insert(user: user) |> Repo.preload(:user)
      alert = %Alert{id: "123", last_push_notification: @monday_at_7am}
      updated_alert = %Alert{id: "123", last_push_notification: @monday_at_8am}
      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: @monday_at_7am,
        subscriptions: [sub1]
      }
      Repo.insert(Notification.create_changeset(notification))
      subscriptions =
        Subscription
        |> Repo.all()
        |> Repo.preload(:user)

      assert {[], []} ==
        SentAlertFilter.filter(subscriptions, alert, [notification], @monday_at_8am)

      assert {[], [returned_sub]} =
        SentAlertFilter.filter(subscriptions, updated_alert, [notification], @monday_at_8am)
      assert returned_sub.id == sub1.id
    end

    test "returns subscriptions to auto resend if within notification window" do
      user = insert(:user)
      subscription_details = %{
        user: user,
        start_time: @monday_at_7am,
        end_time: @monday_at_8am,
        relevant_days: [:monday]
      }
      sub1 = insert(:subscription, subscription_details)
      :subscription |> insert(user: user) |> Repo.preload(:user)
      alert = %Alert{id: "123", last_push_notification: @monday_at_7am}
      updated_alert = %Alert{id: "123", last_push_notification: @monday_at_8am}
      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: @monday_at_7am,
        subscriptions: [sub1]
      }
      Repo.insert(Notification.create_changeset(notification))
      subscriptions =
        Subscription
        |> Repo.all()
        |> Repo.preload(:user)
        |> Repo.preload(:informed_entities)

      assert {[], []} ==
        SentAlertFilter.filter(subscriptions, alert, [notification], @monday_at_8am)

      assert {[], [returned_sub]} =
        SentAlertFilter.filter(subscriptions, updated_alert, [notification], @monday_at_8am)
      assert returned_sub.id == sub1.id
    end

    test "does not return subscription to auto resend if not in notification window" do
      monday_at_10am = DateTime.from_naive!(~N[2018-04-02 10:00:00], "Etc/UTC")
      user = insert(:user)
      sub1 =
        :subscription
        |> insert(user: user, start_time: @monday_at_7am, end_time: @monday_at_8am)
        |> Repo.preload(:user)
      :subscription |> insert(user: user) |> Repo.preload(:user)
      alert = %Alert{id: "123", last_push_notification: @monday_at_7am}
      updated_alert = %Alert{id: "123", last_push_notification: @monday_at_8am}
      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: @monday_at_7am,
        subscriptions: [sub1]
      }
      Repo.insert(Notification.create_changeset(notification))
      subscriptions =
        Subscription
        |> Repo.all()
        |> Repo.preload(:user)
        |> Repo.preload(:informed_entities)

      assert {[], []} ==
        SentAlertFilter.filter(subscriptions, alert, [notification], monday_at_10am)

      assert {[], []} =
        SentAlertFilter.filter(subscriptions, updated_alert, [notification], monday_at_10am)
    end

    test "do not resend if subscription no longer exists" do
      user = insert(:user)
      sub1 = :subscription |> insert(user: user) |> Repo.preload(:user)
      sub2 = :subscription |> insert(user: user) |> Repo.preload(:user)
      alert = %Alert{id: "123", last_push_notification: @monday_at_7am}
      updated_alert = %Alert{id: "123", last_push_notification: @monday_at_8am}
      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: @monday_at_7am,
        notification_subscriptions: [%NotificationSubscription{subscription: sub1}]
      }
      notification2 = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: Calendar.DateTime.subtract!(@monday_at_7am, 1800),
        notification_subscriptions: [%NotificationSubscription{subscription: sub1}]
      }
      Repo.insert(Notification.create_changeset(notification))
      Repo.insert(Notification.create_changeset(notification2))
      subscriptions =
        Subscription
        |> Repo.all()
        |> Repo.preload(:user)
        |> Repo.preload(:informed_entities)

      notifications = Notification.most_recent_for_subscriptions_and_alerts(subscriptions, [alert])

      assert {[], []} ==
        SentAlertFilter.filter(subscriptions, alert, notifications, @monday_at_8am)

      subscriptions =
        Subscription
        |> where([s], s.id != ^sub1.id)
        |> Repo.all()
        |> Repo.preload(:user)
        |> Repo.preload(:informed_entities)

      assert {[returned_sub], []} =
        SentAlertFilter.filter(subscriptions, updated_alert, notifications, @monday_at_8am)
      assert returned_sub.id == sub2.id
    end

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
      :subscription |> insert(user: user) |> Repo.preload(:user)
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
        inserted_at: DateTime.to_naive(monday_april_2_at_8am),
      }

      assert {[], [returned_subscription]} =
        SentAlertFilter.filter([subscription], alert, [notification], monday_april_9_at_7_45am)
      assert returned_subscription.id == subscription.id
    end

    test "if a second reminder is due" do
      monday_april_2_at_8am = DateTime.from_naive!(~N[2018-04-02 08:00:00], "Etc/UTC")
      tuesday_april_10_at_1pm = DateTime.from_naive!(~N[2018-04-10 13:00:00], "Etc/UTC")
      monday_april_16_at_7_01am = DateTime.from_naive!(~N[2018-04-16 07:01:00], "Etc/UTC")
      tuesday_april_17_at_1pm = DateTime.from_naive!(~N[2018-04-17 13:00:00], "Etc/UTC")
      monday_april_23_at_7_01am = DateTime.from_naive!(~N[2018-04-23 07:01:00], "Etc/UTC")
      user = insert(:user)
      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }
      subscription = insert(:subscription, subscription_details)
      :subscription |> insert(user: user) |> Repo.preload(:user)
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
        inserted_at: DateTime.to_naive(monday_april_16_at_7_01am),
      }

      assert {[], [returned_subscription]} =
        SentAlertFilter.filter([subscription], alert, [notification], monday_april_23_at_7_01am)
      assert returned_subscription.id == subscription.id
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
      :subscription |> insert(user: user) |> Repo.preload(:user)
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
        inserted_at: DateTime.to_naive(monday_april_2_at_8am),
      }

      assert {[], []} =
        SentAlertFilter.filter([subscription], alert, [notification], monday_april_9_at_7_30am)
    end

    test "if reminder not due yet and multiple reminder times" do
      monday_april_2_at_8am = DateTime.from_naive!(~N[2018-04-02 08:00:00], "Etc/UTC")
      monday_april_9_at_7_30am = DateTime.from_naive!(~N[2018-04-09 07:30:00], "Etc/UTC")
      monday_april_16_at_7_30am = DateTime.from_naive!(~N[2018-04-16 07:30:00], "Etc/UTC")
      monday_april_23_at_7_30am = DateTime.from_naive!(~N[2018-04-23 07:30:00], "Etc/UTC")
      user = insert(:user)
      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }
      subscription = insert(:subscription, subscription_details)
      :subscription |> insert(user: user) |> Repo.preload(:user)
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
        inserted_at: DateTime.to_naive(monday_april_9_at_7_30am),
      }

      assert {[], []} =
        SentAlertFilter.filter([subscription], alert, [notification], monday_april_16_at_7_30am)
    end

    test "with two reminders that were already sent" do
      monday_april_2_at_8am = DateTime.from_naive!(~N[2018-04-02 08:00:00], "Etc/UTC")
      monday_april_9_at_7_30am = DateTime.from_naive!(~N[2018-04-09 07:30:00], "Etc/UTC")
      monday_april_16_at_7_30am = DateTime.from_naive!(~N[2018-04-16 07:30:00], "Etc/UTC")
      monday_april_23_at_7_30am = DateTime.from_naive!(~N[2018-04-23 07:30:00], "Etc/UTC")
      user = insert(:user)
      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }
      subscription = insert(:subscription, subscription_details)
      :subscription |> insert(user: user) |> Repo.preload(:user)
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
        inserted_at: DateTime.to_naive(monday_april_16_at_7_30am),
      }

      # Note that the third argument is expected to include the latest known
      # sent notification for a user/alert combination.
      assert {[], []} =
        SentAlertFilter.filter([subscription], alert, [notification], monday_april_23_at_7_30am)
    end

    test "reminders are sent within notification window only" do
      monday_april_2_at_8am = DateTime.from_naive!(~N[2018-04-02 08:00:00], "Etc/UTC")
      friday_april_6_at_1pm = DateTime.from_naive!(~N[2018-04-06 13:00:00], "Etc/UTC")
      friday_april_6_at_2pm = DateTime.from_naive!(~N[2018-04-06 14:00:00], "Etc/UTC")
      monday_april_9_at_6am = DateTime.from_naive!(~N[2018-04-09 06:00:00], "Etc/UTC")
      monday_april_9_at_7_30am = DateTime.from_naive!(~N[2018-04-09 07:30:00], "Etc/UTC")
      user = insert(:user)
      subscription_details = %{
        user: user,
        start_time: ~T[07:00:00],
        end_time: ~T[08:00:00],
        relevant_days: [:monday]
      }
      subscription = insert(:subscription, subscription_details)
      :subscription |> insert(user: user) |> Repo.preload(:user)
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
        inserted_at: DateTime.to_naive(monday_april_2_at_8am),
      }

      assert {[], []} =
        SentAlertFilter.filter([subscription], alert, [notification], friday_april_6_at_2pm)
      assert {[], []} =
        SentAlertFilter.filter([subscription], alert, [notification], monday_april_9_at_6am)
      assert {[], [returned_subscription]} =
        SentAlertFilter.filter([subscription], alert, [notification], monday_april_9_at_7_30am)
      assert returned_subscription.id == subscription.id
    end
  end
end
