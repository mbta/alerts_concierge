defmodule AlertProcessor.TextReplacementTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.{Model, TextReplacement}
  alias Model.{Alert, InformedEntity, Subscription}

  setup do
    user = insert(:user)

    {:ok, user: user}
  end

  describe "replace_text/2" do
    test "returns default text if not commuter rail subscription" do
      alert = %Alert{
        header: "test",
        description: "test",
        informed_entities: amenity_subscription_entities()
      }
      subscription = %Subscription{}

      expected = %{
        header: alert.header,
        description: alert.description
      }

      assert TextReplacement.replace_text(alert, [subscription]) == expected
    end

    test "if user doesn't have matching subscription, return original text", %{user: user} do
      sub = :subscription
      |> build(user: user, alert_priority_type: :low, informed_entities: [%InformedEntity{route_type: 2, trip: "222", activities: InformedEntity.default_entity_activities()}])
      |> weekday_subscription()

      alert = %Alert{
        header: "test",
        description: "test",
        informed_entities: commuter_rail_subscription_entities()
      }

      expected = %{
        header: alert.header,
        description: alert.description
      }

      assert TextReplacement.replace_text(alert, [sub]) == expected
    end

    test "if subscription matches alert, and user has different origin station, replace text", %{user: user} do
      sub = %Subscription{
        alert_priority_type: :low,
        destination: "place-north",
        end_time: ~T[02:28:00.000000],
        id: "35c7c2ec-57cd-4f05-8e4f-85033b82262d",
        informed_entities: [
          %AlertProcessor.Model.InformedEntity{
            activities: ["BOARD", "EXIT", "RIDE"], direction_id: nil,
            facility_type: nil, id: "2f38b1bd-a875-4337-a26a-aff96fd37f06",
            inserted_at: ~N[2017-10-26 03:07:32.565705], route: nil, route_type: 2,
            schedule: nil, stop: nil,
            subscription_id: "35c7c2ec-57cd-4f05-8e4f-85033b82262d", trip: nil,
            updated_at: ~N[2017-10-26 03:07:32.565709]
          },
          %AlertProcessor.Model.InformedEntity{
            activities: ["BOARD", "EXIT", "RIDE"], direction_id: nil,
            facility_type: nil, id: "80ad851c-bfcf-4205-bd69-eb81f770234d",
            inserted_at: ~N[2017-10-26 03:07:32.567452], route: "CR-Newburyport",
            route_type: 2, schedule: nil, stop: nil,
            subscription_id: "35c7c2ec-57cd-4f05-8e4f-85033b82262d", trip: nil,
            updated_at: ~N[2017-10-26 03:07:32.567456]},
          %AlertProcessor.Model.InformedEntity{
            activities: ["BOARD", "EXIT", "RIDE"], direction_id: 1, facility_type: nil,
            id: "3ce59d55-b39e-4b35-b4f4-d73c7dcbe166",
            inserted_at: ~N[2017-10-26 03:07:32.568937], route: "CR-Newburyport",
            route_type: 2, schedule: nil, stop: nil,
            subscription_id: "35c7c2ec-57cd-4f05-8e4f-85033b82262d", trip: nil,
            updated_at: ~N[2017-10-26 03:07:32.568940]},
          %AlertProcessor.Model.InformedEntity{
            activities: ["EXIT"], direction_id: nil, facility_type: nil,
            id: "24c11e54-e0c0-42f6-804b-74d28d5a6f7f",
            inserted_at: ~N[2017-10-26 03:07:32.570573], route: "CR-Newburyport",
            route_type: 2, schedule: nil, stop: "place-north",
            subscription_id: "35c7c2ec-57cd-4f05-8e4f-85033b82262d", trip: nil,
            updated_at: ~N[2017-10-26 03:07:32.570576]},
          %AlertProcessor.Model.InformedEntity{
            activities: ["EXIT"], direction_id: 1, facility_type: nil,
            id: "1f1caab5-962d-4cf3-afe1-f178bc8f9d94",
            inserted_at: ~N[2017-10-26 03:07:32.572131], route: "CR-Newburyport",
            route_type: 2, schedule: nil, stop: "place-north",
            subscription_id: "35c7c2ec-57cd-4f05-8e4f-85033b82262d", trip: nil,
            updated_at: ~N[2017-10-26 03:07:32.572134]},
          %AlertProcessor.Model.InformedEntity{
            activities: ["BOARD"], direction_id: nil, facility_type: nil,
            id: "e11d8b93-5d41-455e-9e08-f5b27b061e6c",
            inserted_at: ~N[2017-10-26 03:07:32.573539], route: "CR-Newburyport",
            route_type: 2, schedule: nil, stop: "Chelsea",
            subscription_id: "35c7c2ec-57cd-4f05-8e4f-85033b82262d", trip: nil,
            updated_at: ~N[2017-10-26 03:07:32.573543]},
          %AlertProcessor.Model.InformedEntity{
            activities: ["BOARD"], direction_id: 1, facility_type: nil,
            id: "3431100d-8b55-4a93-8a06-dbab18cb900f",
            inserted_at: ~N[2017-10-26 03:07:32.575013], route: "CR-Newburyport",
            route_type: 2, schedule: nil, stop: "Chelsea",
            subscription_id: "35c7c2ec-57cd-4f05-8e4f-85033b82262d", trip: nil,
            updated_at: ~N[2017-10-26 03:07:32.575017]},
          %AlertProcessor.Model.InformedEntity{
            activities: ["BOARD", "EXIT", "RIDE"], direction_id: nil,
            facility_type: nil, id: "0538083c-e3ff-458d-a6de-91769d6d8606",
            inserted_at: ~N[2017-10-26 03:12:27.516785], route: nil, route_type: nil,
            schedule: nil, stop: nil,
            subscription_id: "35c7c2ec-57cd-4f05-8e4f-85033b82262d", trip: "180",
            updated_at: ~N[2017-10-26 03:12:27.516789]}],
          inserted_at: ~N[2017-10-26 03:07:32.562791], origin: "Chelsea",
          relevant_days: [:weekday], start_time: ~T[02:17:00.000000],
          type: :commuter_rail, updated_at: ~N[2017-10-26 03:12:27.546647],
          user: user}


      alert = %Alert{active_period: [%{end: nil,
      start: %DateTime{calendar: Calendar.ISO, day: 30, hour: 1,
      microsecond: {0, 0}, minute: 25, month: 9, second: 0, std_offset: 0,
      time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"}}],
      created_at: %DateTime{calendar: Calendar.ISO, day: 29, hour: 18,
      microsecond: {0, 0}, minute: 44, month: 9, second: 41, std_offset: 0,
      time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
      description: "Affected direction: Inbound", duration_certainty: :known,
      effect_name: "Delay",
      header: "Newburyport Train 180 (9:25 pm from Newburyport) has departed Newburyport 20-40 minutes late and will operate at a reduced speed due to a mechanical issue.",
      id: "115346",
      informed_entities: [
        %InformedEntity{
          activities: ["BOARD", "EXIT", "RIDE"],
          direction_id: nil,
          facility_type: nil,
          id: nil,
          inserted_at: nil,
          route: "CR-Newburyport",
          route_type: 2,
          schedule: [
            %{arrival_time: "2017-10-30T21:25:00-04:00",
              departure_time: "2017-10-30T21:25:00-04:00", route_id: "CR-Newburyport",
              stop_id: "Newburyport", stop_sequence: 1,
              trip_id: "CR-Weekday-Aug14th-17-NR-180"},
            %{arrival_time: "2017-10-30T21:30:00-04:00",
              departure_time: "2017-10-30T21:30:00-04:00", route_id: "CR-Newburyport",
              stop_id: "Rowley", stop_sequence: 2,
              trip_id: "CR-Weekday-Aug14th-17-NR-180"},
            %{arrival_time: "2017-10-30T21:36:00-04:00",
              departure_time: "2017-10-30T21:36:00-04:00", route_id: "CR-Newburyport",
              stop_id: "Ipswich", stop_sequence: 3,
              trip_id: "CR-Weekday-Aug14th-17-NR-180"},
            %{arrival_time: "2017-10-30T21:42:00-04:00",
              departure_time: "2017-10-30T21:42:00-04:00", route_id: "CR-Newburyport",
              stop_id: "Hamilton/ Wenham", stop_sequence: 4,
              trip_id: "CR-Weekday-Aug14th-17-NR-180"},
            %{arrival_time: "2017-10-30T21:46:00-04:00",
              departure_time: "2017-10-30T21:46:00-04:00", route_id: "CR-Newburyport",
              stop_id: "North Beverly", stop_sequence: 5,
              trip_id: "CR-Weekday-Aug14th-17-NR-180"},
            %{arrival_time: "2017-10-30T21:52:00-04:00",
              departure_time: "2017-10-30T21:52:00-04:00", route_id: "CR-Newburyport",
              stop_id: "Beverly", stop_sequence: 6,
              trip_id: "CR-Weekday-Aug14th-17-NR-180"},
            %{arrival_time: "2017-10-30T21:56:00-04:00",
              departure_time: "2017-10-30T21:56:00-04:00", route_id: "CR-Newburyport",
              stop_id: "Salem", stop_sequence: 7,
              trip_id: "CR-Weekday-Aug14th-17-NR-180"},
            %{arrival_time: "2017-10-30T22:04:00-04:00",
              departure_time: "2017-10-30T22:04:00-04:00", route_id: "CR-Newburyport",
              stop_id: "Swampscott", stop_sequence: 8,
              trip_id: "CR-Weekday-Aug14th-17-NR-180"},
            %{arrival_time: "2017-10-30T22:08:00-04:00",
              departure_time: "2017-10-30T22:08:00-04:00", route_id: "CR-Newburyport",
              stop_id: "Lynn", stop_sequence: 9,
              trip_id: "CR-Weekday-Aug14th-17-NR-180"},
            %{arrival_time: "2017-10-30T22:17:00-04:00",
              departure_time: "2017-10-30T22:17:00-04:00", route_id: "CR-Newburyport",
              stop_id: "Chelsea", stop_sequence: 10,
              trip_id: "CR-Weekday-Aug14th-17-NR-180"},
            %{arrival_time: "2017-10-30T22:28:00-04:00",
              departure_time: "2017-10-30T22:28:00-04:00", route_id: "CR-Newburyport",
              stop_id: "North Station", stop_sequence: 11,
              trip_id: "CR-Weekday-Aug14th-17-NR-180"}],
          stop: nil,
          subscription_id: nil,
          trip: "180",
          updated_at: nil}],
      last_push_notification: %DateTime{calendar: Calendar.ISO, day: 29, hour: 18, microsecond: {0, 0}, minute: 44, month: 9, second: 41, std_offset: 0, time_zone: "Etc/UTC", utc_offset: 0, year: 2017, zone_abbr: "UTC"},
      recurrence: nil,
      service_effect: "Newburyport/Rockport Line delay",
      severity: :moderate,
      timeframe: "ongoing"}

      expected = %{
        header: "Newburyport Train (22:17 PM from Chelsea) has departed Newburyport 20-40 minutes late and will operate at a reduced speed due to a mechanical issue.",
        description: alert.description
      }

      assert TextReplacement.replace_text(alert, [sub]) == expected
    end
  end
end
