defmodule MbtaServer.AlertProcessor.SchedulerTest do
  use MbtaServer.DataCase
  import MbtaServer.Factory
  alias MbtaServer.AlertProcessor.{Scheduler, Model}
  alias Model.Alert
  alias Calendar.DateTime, as: DT
  alias DT.Format, as: F

  setup do
    now = DT.from_date_and_time_and_zone!({2018, 1, 8}, {14, 10, 55}, "Etc/UTC")
    thirty_minutes_from_now = DT.add!(now, 1800)
    one_hour_from_now = DT.add!(now, 3600)
    one_day_from_now = DT.add!(now, 86_400)
    two_days_from_now = DT.add!(now, 172_800)
    three_days_from_now = DT.add!(now, 172_800)

    time = %{
      now: now,
      thirty_minutes_from_now: thirty_minutes_from_now,
      one_hour_from_now: one_hour_from_now,
      one_day_from_now: one_day_from_now,
      two_days_from_now: two_days_from_now,
      three_days_from_now: three_days_from_now
    }

    {:ok, time: time}
  end

  describe "schedule_notifications/2" do
    test "schedules 24 hours in advance of affected period if affected period > 24 hours away", %{time: time} do
      user = insert(:user)
      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: F.rfc3339(time.two_days_from_now), end: F.rfc3339(time.three_days_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert DT.same_time?(notification.send_after, time.one_day_from_now)
    end

    test "schedules for immediate sending if affected period < 24 hours away", %{time: time} do
      user = insert(:user)
      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: F.rfc3339(time.one_hour_from_now), end: F.rfc3339(time.one_day_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)

      assert DT.same_time?(notification.send_after, time.now)
    end

    test "schedules after blackout period if still relevant", %{time: time} do
      user = insert(
        :user,
        do_not_disturb_start: DT.to_time(time.now),
        do_not_disturb_end: DT.to_time(time.thirty_minutes_from_now)
      )

      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: F.rfc3339(time.now), end: F.rfc3339(time.one_day_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert DT.same_time?(notification.send_after, time.thirty_minutes_from_now)
    end

    test "schedules after vacation period if still relevant", %{time: time} do
      user = insert(
        :user,
        vacation_start: time.now,
        vacation_end: time.thirty_minutes_from_now
      )

      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: F.rfc3339(time.one_hour_from_now), end: F.rfc3339(time.one_day_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert DT.same_time?(notification.send_after, time.thirty_minutes_from_now)
    end

    test "does not schedule if affected period ends before vacation", %{time: time} do
      user = insert(
        :user,
        vacation_start: time.now,
        vacation_end: time.one_day_from_now
      )

      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: F.rfc3339(time.thirty_minutes_from_now), end: F.rfc3339(time.one_hour_from_now)}]
      }

      assert {:ok, []} == Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
    end

    test "does not schedule if affected period ends before blackout", %{time: time} do
      user = insert(
        :user,
        do_not_disturb_start: DT.to_time(time.now),
        do_not_disturb_end: DT.to_time(time.one_hour_from_now)
      )

      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: F.rfc3339(time.now), end: F.rfc3339(time.thirty_minutes_from_now)}]
      }

      assert {:ok, []} == Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
    end

    test "handles for no end date on active period", %{time: time} do
      user = insert(:user)
      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: F.rfc3339(time.two_days_from_now), end: nil}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert DT.same_time?(notification.send_after, time.one_day_from_now)
    end

    test "handles no vacation period", %{time: time} do
        user = insert(
        :user,
        vacation_start: nil,
        vacation_end: nil
      )

      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: F.rfc3339(time.one_hour_from_now), end: F.rfc3339(time.one_day_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert DT.same_time?(notification.send_after, time.now)
    end

    test "handles no blackout period", %{time: time} do
      user = insert(
        :user,
        do_not_disturb_start: nil,
        do_not_disturb_end: nil
      )

      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: F.rfc3339(time.now), end: F.rfc3339(time.thirty_minutes_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert DT.same_time?(notification.send_after, time.now)
    end

    test "no active_period end, but has do_not_disturb", %{time: time} do
      user = insert(
        :user,
        do_not_disturb_start: DT.to_time(time.now),
        do_not_disturb_end: DT.to_time(time.one_hour_from_now)
      )

      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: F.rfc3339(time.now), end: nil}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert DT.same_time?(notification.send_after, time.one_hour_from_now)
    end

    test "no active_end, but has vacation", %{time: time} do
      user = insert(
        :user,
        vacation_start: time.now,
        vacation_end: time.one_hour_from_now
      )

      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: F.rfc3339(time.now), end: nil}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert DT.same_time?(notification.send_after, time.one_hour_from_now)
    end
  end

  test "for do_not_disturbs that start/end on same day, alert is scheduled for end of dnd on same day", %{time: time} do
    user = insert(
      :user,
      do_not_disturb_start: DT.to_time(time.now),
      do_not_disturb_end: DT.to_time(time.one_hour_from_now)
    )

    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: F.rfc3339(time.one_day_from_now), end: F.rfc3339(time.two_days_from_now)}]
    }
    {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
    assert notification.send_after == time.one_hour_from_now
  end

  test """
  Schedule alert after DND of same day

  Example:
  It is currently 5am
  DND is set for 8pm - 8am
  The active period is < 24 hours, so the default time to send the alert is immediately
  In this case, the alert would then get scheduled for 8am
  """ do
    today_5am = DT.from_date_and_time_and_zone!({2018, 1, 8}, {5, 0, 0}, "Etc/UTC")
    tomorrow_5am = DT.add!(today_5am, 86_400)
    today_8am = DT.from_date_and_time_and_zone!({2018, 1, 8}, {8, 0, 0}, "Etc/UTC")
    user = insert(
      :user,
      do_not_disturb_start: ~T[20:00:00],
      do_not_disturb_end: ~T[08:00:00]
    )

    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{
        start: F.rfc3339(today_5am),
        end: F.rfc3339(tomorrow_5am)
      }]
    }

    {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, today_5am)
    assert notification.send_after == today_8am
  end

  test """
  Schedule alert after DND of next day

  Example:
  It is currently 10pm
  DND is set for 8pm - 8am
  The default time to send the alert immediately 10pm
  In this case, the alert would then get scheduled for 8am *tomorrow*
  """ do
    today_10pm = DT.from_date_and_time_and_zone!({2018, 1, 8}, {22, 0, 0}, "Etc/UTC")
    tomorrow_10pm = DT.add!(today_10pm, 86_400)
    tomorrow_8am = DT.from_date_and_time_and_zone!({2018, 1, 9}, {8, 0, 0}, "Etc/UTC")
    user = insert(
      :user,
      do_not_disturb_start: ~T[20:00:00],
      do_not_disturb_end: ~T[08:00:00]
    )

    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{
        start: F.rfc3339(tomorrow_10pm),
        end: F.rfc3339(DT.add!(tomorrow_10pm, 86_400))
      }]
    }

    {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, today_10pm)
    assert notification.send_after == tomorrow_8am
  end
end


