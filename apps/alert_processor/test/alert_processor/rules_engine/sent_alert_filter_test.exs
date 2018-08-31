defmodule AlertProcessor.SentAlertFilterTest do
  use AlertProcessor.DataCase, async: true
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

      assert {[sub2], []} ==
               SentAlertFilter.filter([sub1, sub2], @alert, [n1, n2], @monday_at_8am)
    end

    test "returns empty list if no match" do
      assert {[], []} = SentAlertFilter.filter([], @alert, [], @monday_at_8am)
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
               SentAlertFilter.filter(
                 subscriptions,
                 updated_alert,
                 [notification],
                 @monday_at_8am
               )

      assert returned_sub.id == sub1.id
      assert returned_sub.notification_type_to_send == :update
    end

    test "notification_type_to_send is set to `:all_clear`" do
      # If there's `closed_timestamp` in the alert, then it's an "all clear".
      user = insert(:user)

      subscription_details = %{
        user: user,
        start_time: @monday_at_7am,
        end_time: @monday_at_8am,
        relevant_days: [:monday]
      }

      sub1 = insert(:subscription, subscription_details)

      updated_alert = %Alert{
        id: "123",
        last_push_notification: @monday_at_8am,
        closed_timestamp: @monday_at_8am
      }

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

      assert {[], [returned_sub]} =
               SentAlertFilter.filter(
                 subscriptions,
                 updated_alert,
                 [notification],
                 @monday_at_8am
               )

      assert returned_sub.id == sub1.id
      assert returned_sub.notification_type_to_send == :all_clear
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
               SentAlertFilter.filter(
                 subscriptions,
                 updated_alert,
                 [notification],
                 @monday_at_8am
               )

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
               SentAlertFilter.filter(
                 subscriptions,
                 updated_alert,
                 [notification],
                 monday_at_10am
               )
    end

    test "do not resend if subscription no longer exists" do
      user = insert(:user)
      sub1 = :subscription |> insert(user: user) |> Repo.preload(:user)
      _sub2 = :subscription |> insert(user: user) |> Repo.preload(:user)
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

      notifications = Notification.most_recent_for_alerts([alert])

      loaded_subscription =
        notifications
        |> List.first()
        |> Map.get(:subscriptions)
        |> List.first()

      assert loaded_subscription.start_time == ~T[10:00:00.000000]

      assert {[], []} ==
               SentAlertFilter.filter(subscriptions, alert, notifications, @monday_at_8am)

      subscriptions =
        Subscription
        |> where([s], s.id != ^sub1.id)
        |> Repo.all()
        |> Repo.preload(:user)

      assert {[], []} =
               SentAlertFilter.filter(subscriptions, updated_alert, notifications, @monday_at_8am)
    end
  end
end
