defmodule AlertProcessor.Dissemination.MassNotifierTest do
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.Dissemination.MassNotifier
  alias AlertProcessor.{Model.Alert, Model.User, NotificationBuilder, SendingQueue}

  @now Calendar.DateTime.now!("Etc/UTC")
  @two_days_from_now Calendar.DateTime.add!(@now, 172_800)
  @three_days_from_now Calendar.DateTime.add!(@now, 172_800)
  @alert %Alert{
    id: "1",
    header: "test",
    active_period: [%{start: @two_days_from_now, end: @three_days_from_now}],
    service_effect: "test",
    last_push_notification: DateTime.utc_now()
  }

  describe "save_and_enqueue/1" do
    defp insert_user_and_build_notification(user_attrs \\ %{}) do
      user = insert(:user, user_attrs)
      subscription = insert(:subscription, user: user)
      notification = NotificationBuilder.build_notification({user, [subscription]}, @alert)

      {user, notification}
    end

    defp assert_same_notification(notification1, notification2) do
      # Ignore ID which may have changed due to database persistence
      assert Map.drop(notification1, [:id]) == Map.drop(notification2, [:id])
    end

    test "saves and enqueues notifications" do
      {_, notification} = insert_user_and_build_notification()

      :ok = MassNotifier.save_and_enqueue([notification])

      {:ok, queued_notification} = SendingQueue.pop()
      assert_same_notification(notification, queued_notification)
    end

    test "ignores notifications that can't be saved" do
      import ExUnit.CaptureLog

      # replicate the scenario of a user deleting their account during notification processing
      {_, ok_notification} = insert_user_and_build_notification()
      {user_to_delete, bad_notification} = insert_user_and_build_notification()
      User.delete(user_to_delete)

      capture_log(fn ->
        # logs a warning about being unable to save the bad notification
        :ok = MassNotifier.save_and_enqueue([ok_notification, bad_notification])
      end)

      {:ok, queued_notification} = SendingQueue.pop()
      assert_same_notification(ok_notification, queued_notification)
      # the notification for the non-deleted user should have been the only one enqueued
      assert :error = SendingQueue.pop()
    end

    test "enqueues notifications with a phone number ahead of others" do
      {_, first_phone} = insert_user_and_build_notification(%{phone_number: "5555551234"})
      {_, first_email} = insert_user_and_build_notification(%{phone_number: nil})
      {_, second_phone} = insert_user_and_build_notification(%{phone_number: "5555556789"})
      {_, second_email} = insert_user_and_build_notification(%{phone_number: nil})

      :ok = MassNotifier.save_and_enqueue([first_phone, first_email, second_phone, second_email])
      {:ok, first} = SendingQueue.pop()
      {:ok, second} = SendingQueue.pop()
      {:ok, third} = SendingQueue.pop()
      {:ok, fourth} = SendingQueue.pop()

      assert_same_notification(first, first_phone)
      assert_same_notification(second, second_phone)
      assert_same_notification(third, first_email)
      assert_same_notification(fourth, second_email)
    end
  end
end
