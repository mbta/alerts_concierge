defmodule AlertProcessor.AlertParserTest do
  use AlertProcessor.DataCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Bamboo.Test, shared: :true
  import AlertProcessor.Factory
  alias AlertProcessor.{AlertParser, Model}
  alias Model.{Alert, InformedEntity}

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

    use_cassette "route_19_minor_delay", custom: true, clear_mock: true, match_requests_on: [:query] do
      assert [{:ok, [%{
        service_effect: "Minor Route 19 delay",
        header: "Route 19 experiencing minor delays due to traffic"
      }]} | _t] = AlertParser.process_alerts
    end
  end

  test "process_alerts/1 parses alerts and replaces facility id with type" do
    user1 = insert(:user, phone_number: nil)
    :subscription
    |> build(user: user1, alert_priority_type: :low, informed_entities: [%InformedEntity{stop: "place-pktrm", facility_type: :elevator}])
    |> weekday_subscription
    |> insert

    use_cassette "facilities_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      result = AlertParser.process_alerts
      [notification] = Enum.reduce(result, [], fn({:ok, x}, acc) -> acc ++ x end)
      assert notification.header == "Elevator 804 PARK STREET - Tremont Street to the Lobby will be reconstructed and will be out of service through June 2017."
      assert notification.description == "If entering the station, cross Tremont Street to the Boston Common and use Park Street Elevator 978 to the Green Line westbound platform. Red Line platform access is available via the elevator beyond the fare gates. If exiting the station, please travel down the Winter Street Concourse toward Downtown Crossing Station, exit through the fare gates, and take Downtown Crossing Elevator 892 to the street level."
    end
  end
end
