defmodule AlertProcessor.SentAlertFilterTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  alias AlertProcessor.{SentAlertFilter, Model}
  alias Model.{Alert, Notification, NotificationSubscription}
  import AlertProcessor.Factory

  @monday_at_7am DateTime.from_naive!(~N[2018-04-02 07:00:00], "Etc/UTC")
  @monday_at_8am DateTime.from_naive!(~N[2018-04-02 08:00:00], "Etc/UTC")
  @alert %Alert{id: "123", last_push_notification: @monday_at_7am}

  describe "filter/2" do
    test "returns empty list if no match" do
      assert [] = SentAlertFilter.filter(@alert, [], @monday_at_8am)
    end

    test "returns subscriptions to auto resend taken from the recent_notifications" do
      user = insert(:user)

      sub1 =
        insert(:subscription, %{
          user: user,
          start_time: @monday_at_7am,
          end_time: @monday_at_8am,
          relevant_days: [:monday]
        })

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

      assert [returned_sub] =
               SentAlertFilter.filter(updated_alert, [notification], @monday_at_8am)

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

      assert [returned_sub] =
               SentAlertFilter.filter(updated_alert, [notification], @monday_at_8am)

      assert returned_sub.id == sub1.id
      assert returned_sub.notification_type_to_send == :all_clear
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

      assert [] = SentAlertFilter.filter(alert, [notification], monday_at_10am)

      assert [] = SentAlertFilter.filter(updated_alert, [notification], monday_at_10am)
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

      notifications = Notification.most_recent_for_alerts([alert])

      assert [] = SentAlertFilter.filter(alert, notifications, @monday_at_8am)

      assert [] = SentAlertFilter.filter(updated_alert, notifications, @monday_at_8am)
    end
  end
end
