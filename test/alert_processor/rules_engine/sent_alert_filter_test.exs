defmodule MbtaServer.AlertProcessor.SentAlertFilterTest do
  use MbtaServer.DataCase
  alias MbtaServer.AlertProcessor
  alias AlertProcessor.{SentAlertFilter, Model}
  alias Model.{Alert, Notification}
  import MbtaServer.Factory

  setup do
    alert = %Alert{id: "123"}

    {:ok, alert: alert}
  end

  test "filter/2 returns all users who have not received the alert", %{alert: alert} do
    user = insert(:user)
    other_notification_user = insert(:user)
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

    assert {:ok, [user.id, other_notification_user.id], alert} == SentAlertFilter.filter(alert)
  end

  test "filter/2 error if no match", %{alert: alert} do
    assert {:ok, [], alert} == SentAlertFilter.filter(alert)
  end

  test "filter/2 return user if notification failed", %{alert: alert} do
    user = insert(:user)

    notification = %Notification{
      alert_id: "123",
      user_id: user.id,
      email: "a@b.com",
      message: "You are being notified",
      status: :failed
    }

    Repo.insert(Notification.create_changeset(notification))

    assert {:ok, [user.id], alert} == SentAlertFilter.filter(alert)
  end
end
