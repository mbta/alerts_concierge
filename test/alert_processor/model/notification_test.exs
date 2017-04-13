defmodule MbtaServer.AlertProcessor.Model.NotificationTest do
  @moduledoc false
  use MbtaServer.DataCase
  import MbtaServer.Factory

  alias MbtaServer.{AlertProcessor}
  alias AlertProcessor.Model.Notification

  @base_attrs %{
    email: "test@test.com",
    phone_number: "+12345678910",
    header: "Short header",
    message: "There is a delay",
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

  test "create_changeset/2 requires a message", %{valid_attrs: valid_attrs} do
    attrs = Map.delete(valid_attrs, :message)
    changeset = Notification.create_changeset(%Notification{}, attrs)

    refute changeset.valid?
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

  test "save/2 saves notification with given status", %{valid_attrs: valid_attrs} do
    notification = struct(Notification, valid_attrs)
    {:ok, saved_notification} = Notification.save(notification, :sent)

    assert saved_notification.status == :sent
  end
end
