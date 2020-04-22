defmodule AlertProcessor.Dissemination.MassNotifierTest do
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.Dissemination.MassNotifier
  alias AlertProcessor.{Model.Alert, NotificationBuilder, SendingQueue}

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
    test "saves and enqueues notifications" do
      user = insert(:user)
      subscription = insert(:subscription, user: user)
      notification = NotificationBuilder.build_notification({user, [subscription]}, @alert)

      [saved_notification] = MassNotifier.save_and_enqueue([notification])

      {:ok, queued_notification} = SendingQueue.pop()
      assert saved_notification == queued_notification
    end

    test "ignores notifications that can't be saved" do
      import ExUnit.CaptureLog

      # User is intentionally *not* saved to the database. Replicates the scenario of an account
      # being deleted while alerts are being processed.
      user = build(:user)
      subscription = insert(:subscription, user: user)
      notification = NotificationBuilder.build_notification({user, [subscription]}, @alert)

      capture_log(fn ->
        # logs a warning about being unable to save the notification
        [] = MassNotifier.save_and_enqueue([notification])
      end)

      # nothing should have been added to the queue
      :error = SendingQueue.pop()
    end
  end
end
