defmodule AlertProcessor.SchedulerTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.{Scheduler, Model, SendingQueue}
  alias Model.Alert
  alias Calendar.DateTime, as: DT

  setup_all do
    now = Calendar.DateTime.now!("Etc/UTC")
    two_days_from_now = DT.add!(now, 172_800)
    three_days_from_now = DT.add!(now, 172_800)

    time = %{
      now: now,
      two_days_from_now: two_days_from_now,
      three_days_from_now: three_days_from_now
    }

    {:ok, time: time}
  end

  describe "schedule_notifications/2" do
    test "schedules notifications in sending queue", %{time: time} do
      user = insert(:user)
      sub = insert(:subscription, user: user)

      alert = %Alert{
        id: "1",
        header: "test",
        active_period: [%{start: time.two_days_from_now, end: time.three_days_from_now}],
        service_effect: "test",
        last_push_notification: DateTime.utc_now()
      }

      {:ok, [notification]} = Scheduler.schedule_notifications([{user, [sub]}], alert)
      {:ok, queued_notification} = SendingQueue.pop()
      assert notification == queued_notification
    end

    test "ignores notifications that can't be saved", %{time: time} do
      # User is intentionally *not* saved to the database.
      # This replicates the race condition of an account being deleted while alerts are being matched.
      user = build(:user)
      sub = insert(:subscription, user: user)

      alert = %Alert{
        id: "1",
        header: "test",
        active_period: [%{start: time.two_days_from_now, end: time.three_days_from_now}],
        service_effect: "test",
        last_push_notification: DateTime.utc_now()
      }

      {:ok, [_notification]} = Scheduler.schedule_notifications([{user, [sub]}], alert)
      {:ok, queued_notification} = SendingQueue.pop()
      assert queued_notification == nil
    end
  end
end
