defmodule AlertProcessor.AlertParserTest do
  use AlertProcessor.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Bamboo.Test, shared: :true
  import AlertProcessor.Factory
  alias AlertProcessor.{AlertParser, Model}
  alias Model.InformedEntity

  setup_all do
    {:ok, _} = Application.ensure_all_started(:alert_processor)
    HTTPoison.start
    :ok
  end

  test "process_alerts/1" do
    user = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "16"}])
    |> weekday_subscription
    |> insert
    use_cassette "old_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert [{:ok, _} | _t] = AlertParser.process_alerts
    end
    use_cassette "new_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert [{:ok, _} | _t] = AlertParser.process_alerts
    end
  end

  test "process_alerts/1 sends to correct users via filter chain" do
    user1 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user1, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "16"}])
    |> weekday_subscription
    |> insert
    user2 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user2, alert_priority_type: :high, informed_entities: [%InformedEntity{route_type: 3, route: "16"}])
    |> weekday_subscription
    |> insert
    user3 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user3, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "1"}])
    |> weekday_subscription
    |> insert
    user4 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user4, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 3, route: "16"}])
    |> weekday_subscription
    |> insert
    insert(:notification, alert_id: "113724", last_push_notification: ~N[2017-06-23 12:51:02], user: user4, email: user4.email, phone_number: user4.phone_number, status: "sent", send_after: ~N[2017-04-25 10:00:00])

    use_cassette "route_16_minor_delay", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert [{:ok, [%{
        service_effect: "Route 16 delay",
        header: "Route 16 experiencing delays due to fire",
        description: nil
      }]} | _t] = AlertParser.process_alerts
    end
  end

  test "process_alerts/1 parses alerts and replaces facility id with type" do
    user1 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user1, alert_priority_type: :low, informed_entities: [%InformedEntity{stop: "place-chncl", facility_type: :elevator}])
    |> weekday_subscription
    |> insert

    use_cassette "facilities_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      result = AlertParser.process_alerts
      [notification] = Enum.reduce(result, [], fn({:ok, x}, acc) -> acc ++ x end)
      assert notification.header == "Elevator 922 CHINATOWN - Forest Hills Platform to Boylston & Washington Sts unavailable due to maintenance"
      assert notification.description == "If exiting, exit the train at Tufts Medical Center and switch to an Oak Grove-bound train. Exit at Chinatown using Chinatown Elevator 876. If boarding, take the Silver Line to Tufts Medical Center. Alternatively, if you are able, follow Washington Street for one-quarter of a mile to Downtown Crossing Elevator 892 (corner of Winter and Washington Streets)."
    end
  end
end
