defmodule AlertProcessor.SchedulerTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.{Scheduler, Model, HoldingQueue}
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
    test "schedules notifications in holding queue", %{time: time} do
      user = insert(:user)
      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: time.two_days_from_now, end: time.three_days_from_now}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications([{user, [sub]}], alert, time.now)
      {:ok, queued_notification} = HoldingQueue.pop
      assert notification == queued_notification
    end
  end
end
