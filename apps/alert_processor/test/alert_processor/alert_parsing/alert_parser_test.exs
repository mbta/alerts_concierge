defmodule AlertProcessor.AlertParserTest do
  use AlertProcessor.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Bamboo.Test, shared: :true
  import AlertProcessor.Factory
  alias AlertProcessor.{AlertParser, Model.InformedEntity, Model.Notification, NotificationMailer}

  setup_all do
    HTTPoison.start
    :ok
  end

  test "process_alerts/1" do
    user = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "16"}])
    |> weekday_subscription
    |> insert
    use_cassette "old_alerts", custom: true, clear_mock: true do
      assert [{:ok, _} | _t] = AlertParser.process_alerts
    end
    use_cassette "new_alerts", custom: true, clear_mock: true do
      assert [{:ok, _} | _t] = AlertParser.process_alerts
    end
  end

  test "process_alerts/1 sends to correct users via filter chain" do
    user1 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user1, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "19"}])
    |> weekday_subscription
    |> insert
    user2 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user2, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 3, route: "19"}])
    |> weekday_subscription
    |> insert
    user3 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user3, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "1"}])
    |> weekday_subscription
    |> insert
    user4 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user4, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "19"}])
    |> weekday_subscription
    |> insert
    insert(:notification, alert_id: "177528", last_push_notification: ~N[2017-04-11 11:53:33], user: user4, email: user4.email, phone_number: user4.phone_number, status: "sent", send_after: ~N[2017-04-25 10:00:00])
    use_cassette "route_19_minor_delay", custom: true, clear_mock: true do
      assert [{:ok, [%Notification{}]} | _t] = AlertParser.process_alerts
      assert_delivered_email NotificationMailer.notification_email("Route 19 experiencing minor delays due to traffic", user1.email)
    end
  end

  test "process_alerts/1 parses alerts and replaces facility id with type" do
    user1 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user1, alert_priority_type: :low, informed_entities: [%InformedEntity{stop: "place-pktrm", facility_type: :elevator}])
    |> weekday_subscription
    |> insert
    use_cassette "facilities_alerts", custom: true, clear_mock: true do
      AlertParser.process_alerts
      assert_delivered_email NotificationMailer.notification_email("Elevator 804 PARK STREET - Tremont Street to the Lobby will be reconstructed and will be out of service through June 2017.", user1.email)
    end
  end
end
