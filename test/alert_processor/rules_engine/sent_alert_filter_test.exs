defmodule MbtaServer.AlertProcessor.SentAlertFilterTest do
  use MbtaServer.DataCase
  alias MbtaServer.{AlertProcessor, QueryHelper}
  alias AlertProcessor.{SentAlertFilter, Model}
  alias Model.{Alert, Notification}
  import MbtaServer.Factory

  @alert %Alert{id: "123"}

  describe "filter/1" do
    test "returns all users who have not received the alert" do
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

    test "returns the user if notification failed" do
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
  end
end
