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

      assert TextReplacement.replace_text(alert, [subscription]) == alert
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

      assert TextReplacement.replace_text(alert, [sub]) == alert
    end

    test "if subscription matches alert, and user has different origin station, replace text" do
      sub = %Subscription{
        destination: "place-north",
        informed_entities: [
          %AlertProcessor.Model.InformedEntity{
            activities: ["BOARD"],
            stop: "Chelsea"
          }
        ],
        origin: "Chelsea"
      }

      alert = %Alert{
        description: "Affected trips: Newburyport Train 180 (9:25 PM from Newburyport)",
        header: "Newburyport Train 180 (9:25 pm from Newburyport) has departed Newburyport 20-40 minutes late and will operate at a reduced speed due to a mechanical issue.",
        id: "115346",
        informed_entities: [
          %InformedEntity{
            activities: ["BOARD", "EXIT", "RIDE"],
            route: "CR-Newburyport",
            route_type: 2,
            schedule: [
              %{
                 departure_time: "2017-10-30T21:25:00-04:00",
                 stop_id: "Newburyport",
                 trip_id: "CR-Weekday-Aug14th-17-NR-180"
               },
               %{
                departure_time: "2017-10-30T22:17:00-04:00",
                stop_id: "Chelsea",
                trip_id: "CR-Weekday-Aug14th-17-NR-180"
               },
              %{
                departure_time: "2017-10-30T22:28:00-04:00",
                stop_id: "North Station",
                trip_id: "CR-Weekday-Aug14th-17-NR-180"
              }
            ],
            trip: "180"
          }
        ],
      }

      expected = %{
        header: "Newburyport Train (22:17 PM from Chelsea) has departed Newburyport 20-40 minutes late and will operate at a reduced speed due to a mechanical issue.",
        description: "Affected trips: Newburyport Train (22:17 PM from Chelsea)"
      }

      assert TextReplacement.replace_text(alert, [sub]) == Map.merge(alert, expected)
    end
  end
end
