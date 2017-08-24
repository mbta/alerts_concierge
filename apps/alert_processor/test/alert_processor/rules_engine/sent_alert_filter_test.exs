defmodule AlertProcessor.SentAlertFilterTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.{SentAlertFilter, Model}
  alias Model.{Alert, Notification}
  import AlertProcessor.Factory

  @alert %Alert{id: "123", last_push_notification: nil}

  describe "filter/2" do
    test "returns all subscriptions that have not received the alert" do
      notified_user = insert(:user)
      sub1 = insert(:subscription, user: notified_user) |> Repo.preload(:user)
      other_notification_user = insert(:user)
      sub2 = insert(:subscription, user: other_notification_user) |> Repo.preload(:user)

      notification = %Notification{
        alert_id: "123",
        user_id: notified_user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: nil
      }

      other_notification = %Notification{
        alert_id: "456",
        user_id: other_notification_user.id,
        email: "c@d.com",
        header: "You have been notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: nil
      }

      n1 = Repo.insert!(Notification.create_changeset(notification))
      n2 = Repo.insert!(Notification.create_changeset(other_notification))

      assert {:ok, [sub2], @alert} ==
        SentAlertFilter.filter({@alert, [sub1, sub2], [n1, n2]})
    end

    test "returns empty list if no match" do
      assert {:ok, [], @alert} = SentAlertFilter.filter({@alert, [], []})
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
        status: :failed
      }

      Repo.insert(Notification.create_changeset(notification))

      assert {:ok, [subscription], @alert} ==
        SentAlertFilter.filter({@alert, [subscription], [notification]})
    end

    test "returns subscriptions that have received the alert if the last_push_notification changed" do
      user = insert(:user)
      sub1 = insert(:subscription, user: user) |> Repo.preload(:user)
      now = DateTime.utc_now
      later = now |> Calendar.DateTime.add!(1800)
      alert = %Alert{id: "123", last_push_notification: now}
      updated_alert = %Alert{id: "123", last_push_notification: later}
      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        header: "You are being notified",
        service_effect: "test",
        description: "test",
        status: :sent,
        last_push_notification: now
      }
      Repo.insert(Notification.create_changeset(notification))

      assert {:ok, [], alert} ==
        SentAlertFilter.filter({alert, [sub1], [notification]})

      assert {:ok, [sub1], updated_alert} ==
        SentAlertFilter.filter({updated_alert, [sub1], [notification]})
    end
  end
end
