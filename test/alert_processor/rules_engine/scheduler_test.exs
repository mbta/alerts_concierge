defmodule MbtaServer.AlertProcessor.SchedulerTest do
  use MbtaServer.DataCase
  import MbtaServer.Factory
  alias MbtaServer.AlertProcessor.{Scheduler, Model}
  alias Model.Alert

  defp same_time?(time1, time2) do
    {:ok, seconds, _m, _d} = Calendar.DateTime.diff(time1, time2)
    seconds <= 1
  end

  defp format(time) do
    Calendar.DateTime.Format.rfc3339(time)
  end

  setup do
    now = Calendar.DateTime.from_date_and_time_and_zone!({2018, 1, 8}, {14, 10, 55}, "Etc/UTC")

    thirty_minutes_from_now = now
    |> Calendar.DateTime.add!(1800)

    one_hour_from_now = now
    |> Calendar.DateTime.add!(3600)

    one_day_from_now = now
    |> Calendar.DateTime.add!(86_400)

    two_days_from_now = now
    |> Calendar.DateTime.add!(172_800)

    three_days_from_now = now
    |> Calendar.DateTime.add!(172_800)

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
        active_period: [%{start: format(time.two_days_from_now), end: format(time.three_days_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert same_time?(notification.send_after, time.one_day_from_now)
    end

    test "schedules for immediate sending if affected period < 24 hours away", %{time: time} do
      user = insert(:user)
      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: format(time.one_hour_from_now), end: format(time.one_day_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)

      assert same_time?(notification.send_after, time.now)
    end

    test "schedules after blackout period if still relevant", %{time: time} do
      user = insert(
        :user,
        do_not_disturb_start: Calendar.DateTime.to_time(time.now),
        do_not_disturb_end: Calendar.DateTime.to_time(time.thirty_minutes_from_now)
      )

      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: format(time.now), end: format(time.one_day_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert same_time?(notification.send_after, time.thirty_minutes_from_now)
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
        active_period: [%{start: format(time.one_hour_from_now), end: format(time.one_day_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert same_time?(notification.send_after, time.thirty_minutes_from_now)
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
        active_period: [%{start: format(time.thirty_minutes_from_now), end: format(time.one_hour_from_now)}]
      }

      assert {:ok, []} == Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
    end

    test "does not schedule if affected period ends before blackout", %{time: time} do
      user = insert(
        :user,
        do_not_disturb_start: Calendar.DateTime.to_time(time.now),
        do_not_disturb_end: Calendar.DateTime.to_time(time.one_hour_from_now)
      )

      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: format(time.now), end: format(time.thirty_minutes_from_now)}]
      }

      assert {:ok, []} == Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
    end

    test "handles for no end date on active period", %{time: time} do
      user = insert(:user)
      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: format(time.two_days_from_now), end: nil}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert same_time?(notification.send_after, time.one_day_from_now)
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
        active_period: [%{start: format(time.one_hour_from_now), end: format(time.one_day_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert same_time?(notification.send_after, time.now)
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
        active_period: [%{start: format(time.now), end: format(time.thirty_minutes_from_now)}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert same_time?(notification.send_after, time.now)
    end

    test "no active_period end, but has do_not_disturb", %{time: time} do
      user = insert(
        :user,
        do_not_disturb_start: Calendar.DateTime.to_time(time.now),
        do_not_disturb_end: Calendar.DateTime.to_time(time.one_hour_from_now)
      )

      sub = insert(:subscription, user: user)
      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: format(time.now), end: nil}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert same_time?(notification.send_after, time.one_hour_from_now)
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
        active_period: [%{start: format(time.now), end: nil}]
      }

      {:ok, [notification]} = Scheduler.schedule_notifications({:ok, [sub.id], alert}, time.now)
      assert same_time?(notification.send_after, time.one_hour_from_now)
    end
  end
end

# TODO: Test cases for day before/after
