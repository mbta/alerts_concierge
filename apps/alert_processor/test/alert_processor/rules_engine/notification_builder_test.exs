defmodule AlertProcessor.NotificationBuilderTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.{DateHelper, Factory}
  alias AlertProcessor.{Model, NotificationBuilder}
  alias AlertProcessor.Model.Notification
  alias Model.Alert

  describe "build_notification" do
    setup do
      now = naive_to_local(~N[2018-01-11 14:10:55Z])
      one_hour_ago = DateTime.add(now, -3600)
      two_days_from_now = DateTime.add(now, 172_800)
      three_days_from_now = DateTime.add(now, 259_200)

      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: two_days_from_now, end: three_days_from_now}],
        last_push_notification: one_hour_ago
      }

      {:ok, alert: alert}
    end

    test "build notification struct", %{alert: alert} do
      user = insert(:user)
      sub = insert(:subscription, user: user)

      expected_notification = %Notification{
        alert_id: "1",
        user: user,
        user_id: user.id,
        header: nil,
        service_effect: nil,
        description: nil,
        url: alert.url,
        phone_number: nil,
        email: user.email,
        status: :unsent,
        last_push_notification: alert.last_push_notification,
        alert: alert,
        notification_subscriptions: [
          %AlertProcessor.Model.NotificationSubscription{
            subscription_id: sub.id
          }
        ],
        closed_timestamp: alert.closed_timestamp,
        type: :initial
      }

      notification = NotificationBuilder.build_notification({user, [sub]}, alert)

      assert expected_notification == notification
    end

    test "includes email and not phone_number if the user has selected to receive emails", %{
      alert: alert
    } do
      user = insert(:user, communication_mode: "email")
      sub = insert(:subscription, user: user)

      expected_email = user.email

      notification = NotificationBuilder.build_notification({user, [sub]}, alert)

      assert %Notification{email: ^expected_email, phone_number: nil} = notification
    end

    test "includes phone_number and not email if the user has selected to receive text messages",
         %{alert: alert} do
      user = insert(:user, communication_mode: "sms")
      sub = insert(:subscription, user: user)

      expected_phone_number = user.phone_number

      notification = NotificationBuilder.build_notification({user, [sub]}, alert)

      assert %Notification{phone_number: ^expected_phone_number, email: nil} = notification
    end
  end
end
