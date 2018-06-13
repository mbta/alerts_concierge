defmodule AlertProcessor.NotificationBuilderTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.{Model, NotificationBuilder}
  alias AlertProcessor.Model.{Notification, InformedEntity}
  alias Model.Alert
  alias Calendar.DateTime, as: DT

  setup_all do
    now = DT.from_date_and_time_and_zone!({2018, 1, 11}, {14, 10, 55}, "Etc/UTC")
    two_days_ago = DT.subtract!(now, 172_800)
    one_day_ago = DT.subtract!(now, 86_400)
    thirty_minutes_from_now = DT.add!(now, 1800)
    one_hour_from_now = DT.add!(now, 3600)
    one_day_from_now = DT.add!(now, 86_400)
    two_days_from_now = DT.add!(now, 172_800)
    three_days_from_now = DT.add!(now, 172_800)

    utc_time = %{
      now: now,
      thirty_minutes_from_now: thirty_minutes_from_now,
      two_days_ago: two_days_ago,
      one_day_ago: one_day_ago,
      one_hour_from_now: one_hour_from_now,
      one_day_from_now: one_day_from_now,
      two_days_from_now: two_days_from_now,
      three_days_from_now: three_days_from_now
    }

    est_time = for {key, val} <- utc_time, into: %{} do
      {key, DT.shift_zone!(val, "America/New_York")}
    end

    {:ok, est_time: est_time}
  end

  test "build notification struct", %{est_time: est_time} do
    user = insert(:user)
    sub = insert(:subscription, user: user)
    alert = %Alert{
      id: "1",
      header: nil,
      active_period: [%{start: est_time.two_days_from_now, end: est_time.three_days_from_now}]
    }

    notification = NotificationBuilder.build_notification({user, [sub]}, alert)
    expected_notification = %Notification{
      alert_id: "1",
      user: user,
      user_id: user.id,
      header: nil,
      service_effect: nil,
      description: nil,
      url: alert.url,
      phone_number: user.phone_number,
      email: user.email,
      status: :unsent,
      last_push_notification: alert.last_push_notification,
      alert: alert,
      notification_subscriptions: [%AlertProcessor.Model.NotificationSubscription{
        subscription_id: sub.id
      }],
      closed_timestamp: alert.closed_timestamp
    }

    assert expected_notification == notification
  end

  test "logs warning if it errors replacing text" do
    user = build(:user)
    subscription = build(:subscription, user: user)
    alert = %Alert{
      header: "Newburyport Train 180 (25:25 pm from Newburyport)",
      id: "115346",
      informed_entities: [%InformedEntity{route_type: 2}]
    }

    function = fn ->
      NotificationBuilder.build_notification({user, [subscription]}, alert)
    end

    expected_log =
      "Error replacing text: alert_id=\"115346\" "
      <> "error=%ArgumentError{message: \"cannot convert {25, 25, 0} to time, "
      <> "reason: :invalid_time\"}"
    assert ExUnit.CaptureLog.capture_log(function) =~ expected_log
  end
end
