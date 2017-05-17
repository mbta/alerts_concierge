defmodule AlertProcessor.SentAlertFilterTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.{SentAlertFilter, Model, QueryHelper}
  alias Model.{Alert, Notification}
  import AlertProcessor.Factory

  @alert %Alert{id: "123"}

  describe "filter/1" do
    test "returns all subscriptions that have not received the alert" do
      user = insert(:user)
      sub1 = insert(:subscription, user: user)
      other_notification_user = insert(:user)
      sub2 = insert(:subscription, user: other_notification_user)
      notified_user = insert(:user)

      notification = %Notification{
        alert_id: "123",
        user_id: notified_user.id,
        email: "a@b.com",
        message: "You are being notified",
        status: :sent
      }

      other_notification = %Notification{
        alert_id: "456",
        user_id: other_notification_user.id,
        email: "c@d.com",
        message: "You have been notified",
        status: :sent
      }

      Repo.insert(Notification.create_changeset(notification))
      Repo.insert(Notification.create_changeset(other_notification))

      assert {:ok, query, @alert} = SentAlertFilter.filter(@alert)
      assert MapSet.equal?(MapSet.new([sub1.id, sub2.id]), MapSet.new(QueryHelper.execute_query(query)))
    end

    test "returns empty list if no match" do
      assert {:ok, query, @alert} = SentAlertFilter.filter(@alert)
      assert [] == QueryHelper.execute_query(query)
    end

    test "returns the subscription if notification failed" do
      user = insert(:user)
      subscription = insert(:subscription, user: user)

      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        message: "You are being notified",
        status: :failed
      }

      Repo.insert(Notification.create_changeset(notification))

      assert {:ok, query, @alert} = SentAlertFilter.filter(@alert)
      assert [subscription.id] == QueryHelper.execute_query(query)
    end

    test "returns subscriptions that have received the alert if the last_push_notification changed" do
      user = insert(:user)
      sub1 = insert(:subscription, user: user)
      now = DateTime.utc_now
      later = now |> Calendar.DateTime.add!(1800)
      alert = %Alert{id: "123", last_push_notification: now}
      updated_alert = %Alert{id: "123", last_push_notification: later}
      notification = %Notification{
        alert_id: "123",
        user_id: user.id,
        email: "a@b.com",
        message: "You are being notified",
        status: :sent,
        last_push_notification: now
      }
      Repo.insert(Notification.create_changeset(notification))

      assert {:ok, query, _alert} = SentAlertFilter.filter(alert)
      assert [] == QueryHelper.execute_query(query)

      assert {:ok, query2, _alert2} = SentAlertFilter.filter(updated_alert)
      assert [sub1.id] == QueryHelper.execute_query(query2)
    end
  end
end
