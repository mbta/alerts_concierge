defmodule AlertProcessor.NotificationBuilderTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.{DateHelper, Factory}
  alias AlertProcessor.Model.InformedEntity
  alias AlertProcessor.{Model, NotificationBuilder}
  alias AlertProcessor.Model.Notification
  alias Model.Alert

  describe "build_notification" do
    setup do
      now = naive_to_local(~N[2018-01-11 14:10:55Z])
      one_hour_ago = DateTime.add(now, -1, :hour)
      two_days_from_now = DateTime.add(now, 2, :day)
      three_days_from_now = DateTime.add(now, 3, :day)

      alert = %Alert{
        id: "1",
        header: nil,
        active_period: [%{start: two_days_from_now, end: three_days_from_now}],
        last_push_notification: one_hour_ago,
        image_url: "http://example.com/cool_image.png",
        image_alternative_text: "a cool image"
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
        call_to_action: nil,
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
        type: :initial,
        image_url: "http://example.com/cool_image.png",
        image_alternative_text: "a cool image"
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

  describe "Notification.call_to_action" do
    setup do
      user = insert(:user)
      sub = insert(:subscription, user: user)

      {:ok, user_subs: {user, [sub]}}
    end

    test "includes dotcom url and mbta go CTA if single bus route is effected", %{
      user_subs: user_subs
    } do
      now = naive_to_local(~N[2018-01-11 14:10:55Z])
      one_hour_ago = DateTime.add(now, -1, :hour)
      two_days_from_now = DateTime.add(now, 2, :day)
      three_days_from_now = DateTime.add(now, 3, :day)

      alert = %Alert{
        id: "1",
        header: nil,
        effect_name: "Delay",
        active_period: [%{start: two_days_from_now, end: three_days_from_now}],
        informed_entities: [%InformedEntity{route_type: 3, route: "1"}],
        last_push_notification: one_hour_ago
      }

      notification = NotificationBuilder.build_notification(user_subs, alert)

      assert %Notification{
               call_to_action:
                 "Track your bus at https://mbta.com/route/1 or use the MBTA Go app: https://go.mbta.com/t-alert"
             } = notification
    end

    test "includes only mbta go CTA if multiple bus routes are effected", %{user_subs: user_subs} do
      now = naive_to_local(~N[2018-01-11 14:10:55Z])
      one_hour_ago = DateTime.add(now, -1, :hour)
      two_days_from_now = DateTime.add(now, 2, :day)
      three_days_from_now = DateTime.add(now, 3, :day)

      alert = %Alert{
        id: "1",
        header: nil,
        effect_name: "Delay",
        active_period: [%{start: two_days_from_now, end: three_days_from_now}],
        informed_entities: [
          %InformedEntity{route_type: 3, route: "1"},
          %InformedEntity{route_type: 3, route: "66"},
          %InformedEntity{route_type: 3, route: "72"}
        ],
        last_push_notification: one_hour_ago
      }

      notification = NotificationBuilder.build_notification(user_subs, alert)

      assert %Notification{
               call_to_action:
                 "To track your bus, use the MBTA Go app: https://go.mbta.com/t-alert"
             } = notification
    end

    test "nil cta when not a delay alert", %{user_subs: user_subs} do
      now = naive_to_local(~N[2018-01-11 14:10:55Z])
      one_hour_ago = DateTime.add(now, -1, :hour)
      two_days_from_now = DateTime.add(now, 2, :day)
      three_days_from_now = DateTime.add(now, 3, :day)

      alert = %Alert{
        id: "1",
        header: nil,
        effect_name: "Detour",
        active_period: [%{start: two_days_from_now, end: three_days_from_now}],
        informed_entities: [%InformedEntity{route_type: 3, route: "1"}],
        last_push_notification: one_hour_ago
      }

      notification = NotificationBuilder.build_notification(user_subs, alert)

      assert %Notification{call_to_action: nil} = notification
    end

    test "nil cta for rail delay", %{user_subs: user_subs} do
      now = naive_to_local(~N[2018-01-11 14:10:55Z])
      one_hour_ago = DateTime.add(now, -1, :hour)
      two_days_from_now = DateTime.add(now, 2, :day)
      three_days_from_now = DateTime.add(now, 3, :day)

      alert = %Alert{
        id: "Red",
        header: nil,
        effect_name: "Delay",
        active_period: [%{start: two_days_from_now, end: three_days_from_now}],
        informed_entities: [%InformedEntity{route_type: 1, route: "Red"}],
        last_push_notification: one_hour_ago
      }

      notification = NotificationBuilder.build_notification(user_subs, alert)

      assert %Notification{call_to_action: nil} = notification
    end
  end
end
