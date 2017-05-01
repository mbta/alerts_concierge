defmodule MbtaServer.AlertProcessor.NotificationBuilderTest do
  use MbtaServer.DataCase
  import MbtaServer.Factory
  alias MbtaServer.AlertProcessor.{Model, NotificationBuilder}
  alias Model.Alert
  alias Calendar.DateTime, as: DT

  setup do
    now = DT.from_date_and_time_and_zone!({2018, 1, 8}, {14, 10, 55}, "Etc/UTC")
    two_days_ago = DT.subtract!(now, 172_800)
    one_day_ago = DT.subtract!(now, 86_400)
    thirty_minutes_from_now = DT.add!(now, 1800)
    one_hour_from_now = DT.add!(now, 3600)
    one_day_from_now = DT.add!(now, 86_400)
    two_days_from_now = DT.add!(now, 172_800)
    three_days_from_now = DT.add!(now, 172_800)

    time = %{
      now: now,
      thirty_minutes_from_now: thirty_minutes_from_now,
      two_days_ago: two_days_ago,
      one_day_ago: one_day_ago,
      one_hour_from_now: one_hour_from_now,
      one_day_from_now: one_day_from_now,
      two_days_from_now: two_days_from_now,
      three_days_from_now: three_days_from_now
    }

    {:ok, time: time}
  end

  test "build notifications for each active period of an alert", %{time: time} do
    user = insert(:user)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.two_days_from_now, end: time.three_days_from_now}]
    }

    [notification] = NotificationBuilder.build_notifications(sub, alert, time.now)
    assert DT.same_time?(notification.send_after, time.one_day_from_now)
  end

  test "do not build expired notifications", %{time: time} do
    user = insert(:user)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.two_days_ago, end: time.one_day_ago}]
    }

    assert Enum.empty? NotificationBuilder.build_notifications(sub, alert, time.now)
  end

  test "set send after to current time for immediate alerts", %{time: time} do
    user = insert(:user)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.thirty_minutes_from_now, end: time.one_day_from_now}]
    }

    [notification] = NotificationBuilder.build_notifications(sub, alert, time.now)
    assert DT.same_time?(notification.send_after, time.now)
  end

  test "set send after to 24 hours before start of active period", %{time: time} do
    user = insert(:user)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.two_days_from_now, end: time.three_days_from_now}]
    }

    [notification] = NotificationBuilder.build_notifications(sub, alert, time.now)
    assert DT.same_time?(notification.send_after, time.one_day_from_now)
  end

  test "do not send notification if send_time - active_period end is inside vacation period", %{time: time} do
    user = insert(:user, vacation_start: time.now, vacation_end: time.two_days_from_now)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.thirty_minutes_from_now, end: time.one_day_from_now}]
    }

    assert Enum.empty? NotificationBuilder.build_notifications(sub, alert, time.now)
  end

  test "send notification at end of vacation period if active_period overlaps", %{time: time} do
    user = insert(:user, vacation_start: time.now, vacation_end: time.one_day_from_now)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.thirty_minutes_from_now, end: time.three_days_from_now}]
    }

    [notification] = NotificationBuilder.build_notifications(sub, alert, time.now)
    assert DT.same_time?(notification.send_after, time.one_day_from_now)
  end

  test "do not send notification if send_time -> active_period end is inside blackout period", %{time: time} do
    user = insert(
      :user,
      do_not_disturb_start: DT.to_time(time.now),
      do_not_disturb_end: DT.to_time(time.one_hour_from_now)
    )
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.now, end: time.thirty_minutes_from_now}]
    }

    assert Enum.empty?  NotificationBuilder.build_notifications(sub, alert, time.now)
  end

  test "send notification at end of blackout period if active_period overlaps", %{time: time} do
    user = insert(
      :user,
      do_not_disturb_start: DT.to_time(time.now),
      do_not_disturb_end: DT.to_time(time.one_hour_from_now)
    )
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: time.now, end: time.one_day_from_now}]
    }

    [notification] = NotificationBuilder.build_notifications(sub, alert, time.now)
    assert DT.same_time?(notification.send_after, time.one_hour_from_now)
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
        start: today_5am,
        end: tomorrow_5am
      }]
    }

    [notification] = NotificationBuilder.build_notifications(sub, alert, today_5am)
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
        start: tomorrow_10pm,
        end: DT.add!(tomorrow_10pm, 86_400)
      }]
    }

     [notification] = NotificationBuilder.build_notifications(sub, alert, today_10pm)
     assert notification.send_after == tomorrow_8am
  end
end
