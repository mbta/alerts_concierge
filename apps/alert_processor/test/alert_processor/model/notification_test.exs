defmodule AlertProcessor.Model.NotificationTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory

  alias AlertProcessor.Model.{Alert, Notification, NotificationSubscription}

  @base_attrs %{
    email: "test@test.com",
    phone_number: "2345678910",
    header: "Short header",
    service_effect: "There is a delay",
    description: "The delay is for 1 hour at south station",
    url: "http://www.example.com/alert-info",
    send_after: DateTime.utc_now(),
    alert_id: "12345678",
    status: :sent
  }

  setup do
    user = insert(:user)
    valid_attrs = Map.put(@base_attrs, :user_id, user.id)

    {:ok, user: user, valid_attrs: valid_attrs}
  end

  test "create_changeset/2 with valid parameters", %{valid_attrs: valid_attrs} do
    changeset = Notification.create_changeset(%Notification{}, valid_attrs)
    assert changeset.valid?
  end

  test "create_changeset/2 requires a user_id", %{valid_attrs: valid_attrs} do
    attrs = Map.delete(valid_attrs, :user_id)
    changeset = Notification.create_changeset(%Notification{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 requires an alert_id", %{valid_attrs: valid_attrs} do
    attrs = Map.delete(valid_attrs, :alert_id)
    changeset = Notification.create_changeset(%Notification{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 requires a header", %{valid_attrs: valid_attrs} do
    attrs = Map.delete(valid_attrs, :header)
    changeset = Notification.create_changeset(%Notification{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 requires a service_effect", %{valid_attrs: valid_attrs} do
    attrs = Map.delete(valid_attrs, :service_effect)
    changeset = Notification.create_changeset(%Notification{}, attrs)

    refute changeset.valid?
  end

  test "create_changeset/2 does not require a description", %{valid_attrs: valid_attrs} do
    attrs = Map.delete(valid_attrs, :description)
    changeset = Notification.create_changeset(%Notification{}, attrs)

    assert changeset.valid?
  end

  test "create_changeset/2 does not require a url", %{valid_attrs: valid_attrs} do
    attrs = Map.delete(valid_attrs, :url)
    changeset = Notification.create_changeset(%Notification{}, attrs)

    assert changeset.valid?
  end

  test "create_changeset/2 requires an email OR phone number", %{valid_attrs: valid_attrs} do
    no_phone_attrs = Map.delete(valid_attrs, :phone_number)
    no_phone_changeset = Notification.create_changeset(%Notification{}, no_phone_attrs)

    no_email_attrs = Map.delete(valid_attrs, :email)
    no_email_changeset = Notification.create_changeset(%Notification{}, no_email_attrs)

    no_email_or_phone_attrs = Map.delete(no_email_attrs, :phone_number)

    no_email_or_phone_changeset =
      Notification.create_changeset(%Notification{}, no_email_or_phone_attrs)

    assert no_phone_changeset.valid?
    assert no_email_changeset.valid?
    refute no_email_or_phone_changeset.valid?
  end

  test "create_changeset/2 validates inclusion of status", %{valid_attrs: valid_attrs} do
    invalid_attrs = Map.put(valid_attrs, :status, "example")
    invalid_changeset = Notification.create_changeset(%Notification{}, invalid_attrs)

    valid = Map.put(valid_attrs, :status, :sent)
    valid_changeset = Notification.create_changeset(%Notification{}, valid)

    valid_2 = Map.put(valid_attrs, :status, :failed)
    valid_changeset_2 = Notification.create_changeset(%Notification{}, valid_2)

    assert valid_changeset.valid?
    assert valid_changeset_2.valid?
    refute invalid_changeset.valid?
  end

  test "save/2 saves notification with given status", %{user: user, valid_attrs: valid_attrs} do
    notification = struct(Notification, Map.put(valid_attrs, :user, user))
    {:ok, saved_notification} = Notification.save(notification, :sent)

    assert saved_notification.status == :sent
  end

  test "sent_to_user/1 returns sent notifications to user", %{
    user: user,
    valid_attrs: valid_attrs
  } do
    notification = struct(Notification, Map.put(valid_attrs, :user, user))
    {:ok, saved_notification_1} = Notification.save(notification, :sent)
    {:ok, _} = Notification.save(notification, :failed)
    other_user = insert(:user)

    other_notification =
      struct(Notification, Map.merge(valid_attrs, %{user_id: other_user.id, user: other_user}))

    {:ok, _} = Notification.save(other_notification, :sent)
    [%Notification{id: returned_notification_id}] = Notification.sent_to_user(user)
    assert returned_notification_id == saved_notification_1.id
  end

  describe "most_recent_for_alerts/1" do
    test "returns most recent notification by inserted_at" do
      user = insert(:user)

      for notification_number <- 1..5 do
        notification = struct(Notification, notification_details("1", notification_number, user))
        Notification.save(notification, :sent)
      end

      [latest_notification] = Notification.most_recent_for_alerts([%{id: "1"}])

      assert latest_notification.header == "notification 5"
    end

    test "returns a single notification per alert" do
      user = insert(:user)

      for alert_id <- 1..2, notification_number <- 1..2 do
        notification =
          struct(
            Notification,
            notification_details(Integer.to_string(alert_id), notification_number, user)
          )

        Notification.save(notification, :sent)
      end

      latest_notifications = Notification.most_recent_for_alerts([%{id: "1"}, %{id: "2"}])

      assert length(latest_notifications) == 2
      assert Enum.any?(latest_notifications, &(&1.alert_id == "1"))
      assert Enum.any?(latest_notifications, &(&1.alert_id == "2"))
    end

    test "returns a single notification per user" do
      user1 = insert(:user, email: "user1@emailprovider.com")
      user2 = insert(:user, email: "user2@emailprovider.com")

      for user <- [user1, user2], notification_number <- 1..2 do
        notification = struct(Notification, notification_details("1", notification_number, user))
        Notification.save(notification, :sent)
      end

      latest_notifications = Notification.most_recent_for_alerts([%{id: "1"}])

      assert length(latest_notifications) == 2
      assert Enum.any?(latest_notifications, &(&1.user_id == user1.id))
      assert Enum.any?(latest_notifications, &(&1.user_id == user2.id))
    end

    test "ignores irrelevant alerts" do
      user = insert(:user)

      for alert_id <- 1..2 do
        notification =
          struct(Notification, notification_details(Integer.to_string(alert_id), "1", user))

        Notification.save(notification, :sent)
      end

      [%{alert_id: alert_id}] = Notification.most_recent_for_alerts([%{id: "1"}])

      assert alert_id == "1"
    end

    test "ignores alerts with non-sent status" do
      user = insert(:user)

      for status <- [:failed, :sent] do
        notification = struct(Notification, notification_details("1", "1", user))
        Notification.save(notification, status)
      end

      [%{status: status}] = Notification.most_recent_for_alerts([%{id: "1"}])

      assert status == :sent
    end

    test "preloads subscriptions and it's users" do
      user = insert(:user)
      subscription = insert(:subscription, user: user)

      notification =
        struct(
          Notification,
          notification_details("1", "1", user, [
            %NotificationSubscription{subscription: subscription}
          ])
        )

      Notification.save(notification, :sent)

      [latest_notification] = Notification.most_recent_for_alerts([%{id: "1"}])

      assert [subscription] = latest_notification.subscriptions
      assert subscription.user == user
    end
  end

  describe "most_recent_if_outdated_for_alert/1" do
    test "returns most recent notification by inserted_at" do
      user = insert(:user)

      for notification_number <- 1..5 do
        notification = struct(Notification, notification_details("1", notification_number, user))
        Notification.save(notification, :sent)
      end

      alert = %Alert{id: "1", last_push_notification: DateTime.utc_now()}
      [latest_notification] = Notification.most_recent_if_outdated_for_alert(alert)

      assert latest_notification.header == "notification 5"
    end

    test "ignores most recent notifications that were last pushed more recently than the alert" do
      alert = %Alert{id: "1", last_push_notification: DateTime.utc_now()}
      user = insert(:user)

      # The outdated notification would be returned by this function if there weren't a newer notification for this alert and user with the same last_push_notification as the alert
      outdated_notification =
        struct(Notification, %{
          notification_details("1", 1, user)
          | last_push_notification: alert.last_push_notification |> Calendar.DateTime.subtract!(1)
        })

      Notification.save(outdated_notification, :sent)

      up_to_date_notification =
        struct(Notification, %{
          notification_details("1", 1, user)
          | last_push_notification: alert.last_push_notification
        })

      Notification.save(up_to_date_notification, :sent)

      assert [] = Notification.most_recent_if_outdated_for_alert(alert)
    end

    test "returns a single notification per user" do
      user1 = insert(:user, email: "user1@emailprovider.com")
      user2 = insert(:user, email: "user2@emailprovider.com")

      for user <- [user1, user2], notification_number <- 1..2 do
        notification = struct(Notification, notification_details("1", notification_number, user))
        Notification.save(notification, :sent)
      end

      alert = %Alert{id: "1", last_push_notification: DateTime.utc_now()}
      latest_notifications = Notification.most_recent_if_outdated_for_alert(alert)

      assert length(latest_notifications) == 2
      assert Enum.any?(latest_notifications, &(&1.user_id == user1.id))
      assert Enum.any?(latest_notifications, &(&1.user_id == user2.id))
    end

    test "ignores irrelevant alerts" do
      user = insert(:user)

      for alert_id <- 1..2 do
        notification =
          struct(Notification, notification_details(Integer.to_string(alert_id), "1", user))

        Notification.save(notification, :sent)
      end

      alert = %Alert{id: "1", last_push_notification: DateTime.utc_now()}
      [%{alert_id: alert_id}] = Notification.most_recent_if_outdated_for_alert(alert)

      assert alert_id == "1"
    end

    test "ignores alerts with non-sent status" do
      user = insert(:user)

      for status <- [:failed, :sent] do
        notification = struct(Notification, notification_details("1", "1", user))
        Notification.save(notification, status)
      end

      alert = %Alert{id: "1", last_push_notification: DateTime.utc_now()}
      [%{status: status}] = Notification.most_recent_if_outdated_for_alert(alert)

      assert status == :sent
    end

    test "preloads subscriptions and it's users" do
      user = insert(:user)
      subscription = insert(:subscription, user: user)

      notification =
        struct(
          Notification,
          notification_details("1", "1", user, [
            %NotificationSubscription{subscription: subscription}
          ])
        )

      Notification.save(notification, :sent)

      alert = %Alert{id: "1", last_push_notification: DateTime.utc_now()}
      [latest_notification] = Notification.most_recent_if_outdated_for_alert(alert)

      assert [subscription] = latest_notification.subscriptions
      assert subscription.user == user
    end
  end

  defp notification_details(
         alert_id,
         notification_number,
         user,
         notification_subscriptions \\ []
       ) do
    %{
      alert_id: alert_id,
      header: "notification #{notification_number}",
      service_effect: "some service effect",
      user: user,
      email: user.email,
      last_push_notification: DateTime.utc_now(),
      notification_subscriptions: notification_subscriptions
    }
  end
end
