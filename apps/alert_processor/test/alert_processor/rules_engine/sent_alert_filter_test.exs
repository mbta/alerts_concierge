defmodule AlertProcessor.SentAlertFilterTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.{SentAlertFilter, Model}
  alias Model.{Alert, Notification}
  import AlertProcessor.Factory

  @now DateTime.utc_now
  @later Calendar.DateTime.add!(@now, 1800)
  @alert %Alert{id: "123", last_push_notification: @now}

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
        last_push_notification: @later,
        subscription_ids: [sub1.id]
      }

      other_notification = %Notification{
        alert_id: "456",
        user_id: other_notification_user.id,
        email: "c@d.com",
        header: "You have been notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: @later,
        subscription_ids: [sub2.id]
      }

      n1 = Repo.insert!(Notification.create_changeset(notification))
      n2 = Repo.insert!(Notification.create_changeset(other_notification))

      assert {[sub2],  []} ==
        SentAlertFilter.filter([sub1, sub2], alert: @alert, notifications: [n1, n2])
    end

    test "returns empty list if no match" do
      assert {[], []} = SentAlertFilter.filter([], alert: @alert, notifications: [])
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
        subscription_ids: []
      }

      Repo.insert(Notification.create_changeset(notification))

      assert {[subscription], []} ==
        SentAlertFilter.filter([subscription], alert: @alert, notifications: [notification])
    end

    test "returns subscriptions to auto resend that have received the alert if the last_push_notification changed" do
      user = insert(:user)
      sub1 = :subscription |> insert(user: user) |> Repo.preload(:user)
      sub2 = :subscription |> insert(user: user) |> Repo.preload(:user)
      alert = %Alert{id: "123", last_push_notification: @now}
      updated_alert = %Alert{id: "123", last_push_notification: @later}
      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: @now,
        subscription_ids: [sub1.id]
      }
      Repo.insert(Notification.create_changeset(notification))

      assert {[], []} ==
        SentAlertFilter.filter([sub1, sub2], alert: alert, notifications: [notification])

      assert {[], [sub1]} ==
        SentAlertFilter.filter([sub1, sub2], alert: updated_alert, notifications: [notification])
    end

    test "do not resend if subscription no longer exists" do
      user = insert(:user)
      sub1 = :subscription |> insert(user: user) |> Repo.preload(:user)
      sub2 = :subscription |> insert(user: user) |> Repo.preload(:user)
      alert = %Alert{id: "123", last_push_notification: @now}
      updated_alert = %Alert{id: "123", last_push_notification: @later}
      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: @now,
        subscription_ids: [sub1.id]
      }
      Repo.insert(Notification.create_changeset(notification))

      assert {[], []} ==
        SentAlertFilter.filter([sub1, sub2], alert: alert, notifications: [notification])

      assert {[sub2], []} ==
        SentAlertFilter.filter([sub2], alert: updated_alert, notifications: [notification])
    end
  end
end
