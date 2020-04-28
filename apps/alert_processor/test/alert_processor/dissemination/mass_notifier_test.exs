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
    defp insert_user_and_build_notification do
      user = insert(:user)
      subscription = insert(:subscription, user: user)
      notification = NotificationBuilder.build_notification({user, [subscription]}, @alert)

      {user, notification}
    end

    test "saves and enqueues notifications" do
      {_, notification} = insert_user_and_build_notification()

      :ok = MassNotifier.save_and_enqueue([notification])

      {:ok, queued_notification} = SendingQueue.pop()
      assert Map.drop(notification, [:id]) == Map.drop(queued_notification, [:id])
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
      assert Map.drop(ok_notification, [:id]) == Map.drop(queued_notification, [:id])
      # the notification for the non-deleted user should have been the only one enqueued
      assert :error = SendingQueue.pop()
    end
  end
end
