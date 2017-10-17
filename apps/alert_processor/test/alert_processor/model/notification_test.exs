defmodule AlertProcessor.Model.NotificationTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory

  alias AlertProcessor.Model.{Notification, NotificationSubscription}

  @base_attrs %{
    email: "test@test.com",
    phone_number: "2345678910",
    header: "Short header",
    service_effect: "There is a delay",
    description: "The delay is for 1 hour at south station",
    send_after: DateTime.utc_now,
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

  test "create_changeset/2 requires an email OR phone number", %{valid_attrs: valid_attrs} do
    no_phone_attrs = Map.delete(valid_attrs, :phone_number)
    no_phone_changeset = Notification.create_changeset(%Notification{}, no_phone_attrs)

    no_email_attrs = Map.delete(valid_attrs, :email)
    no_email_changeset = Notification.create_changeset(%Notification{}, no_email_attrs)

    no_email_or_phone_attrs = Map.delete(no_email_attrs, :phone_number)
    no_email_or_phone_changeset = Notification.create_changeset(%Notification{}, no_email_or_phone_attrs)

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

  test "sent_to_user/1 returns sent notifications to user", %{user: user, valid_attrs: valid_attrs} do
    notification = struct(Notification, Map.put(valid_attrs, :user, user))
    {:ok, saved_notification_1} = Notification.save(notification, :sent)
    {:ok, _} = Notification.save(notification, :failed)
    other_user = insert(:user)
    other_notification = struct(Notification, Map.merge(valid_attrs, %{user_id: other_user.id, user: other_user}))
    {:ok, _} = Notification.save(other_notification, :sent)
    [%Notification{id: returned_notification_id}] = Notification.sent_to_user(user)
    assert returned_notification_id == saved_notification_1.id
  end

  test "most_recent_for_subscriptions_and_alerts/2 only returns latest notification by last_push_notification for alert/user combo" do
    now = DateTime.utc_now()
    later = Calendar.DateTime.add!(now, 1800)
    user1 = insert(:user)
    sub1 = insert(:subscription, user: user1)

    notification1 = struct(Notification, Map.merge(@base_attrs, %{user: user1, last_push_notification: now, notification_subscriptions: [%NotificationSubscription{subscription: sub1}]}))
    {:ok, saved_notification_1} = Notification.save(notification1, :sent)
    notification2 = struct(Notification, Map.merge(@base_attrs, %{user: user1, last_push_notification: later, notification_subscriptions: [%NotificationSubscription{subscription: sub1}]}))
    {:ok, saved_notification_2} = Notification.save(notification2, :sent)
    notification3 = struct(Notification, Map.merge(@base_attrs, %{user: user1, last_push_notification: now, alert_id: "55555", notification_subscriptions: [%NotificationSubscription{subscription: sub1}]}))
    {:ok, saved_notification_3} = Notification.save(notification3, :sent)

    notifications = Notification.most_recent_for_subscriptions_and_alerts([sub1], [%{id: "12345678"}, %{id: "55555"}])
    returned_notification_ids = Enum.map(notifications, & &1.id)
    refute Enum.member?(returned_notification_ids, saved_notification_1.id)
    assert Enum.member?(returned_notification_ids, saved_notification_2.id)
    assert Enum.member?(returned_notification_ids, saved_notification_3.id)
    [returned_notification1, returned_notification2] = notifications
    assert [sub1.id] == Enum.map(returned_notification1.subscriptions, & &1.id)
    assert [sub1.id] == Enum.map(returned_notification2.subscriptions, & &1.id)
  end
end
