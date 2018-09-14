defmodule AlertProcessor.TextReplacementTest do
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.{Model, TextReplacement}
  alias Model.{Alert, InformedEntity, Subscription}
  doctest TextReplacement

  describe "replace_text!/2" do
    test "returns default text if not commuter rail subscription" do
      alert = %Alert{
        header: "test",
        description: "test",
        informed_entities: []
      }

      subscription = %Subscription{}

      assert TextReplacement.replace_text!(alert, [subscription]) == alert
    end

    test "if subscriptions don't match , return original text" do
      sub =
        :subscription
        |> build(
          informed_entities: [
            %InformedEntity{
              route_type: 2,
              trip: "222",
              activities: InformedEntity.default_entity_activities()
            }
          ]
        )
        |> weekday_subscription()

      alert = %Alert{
        header: "test",
        description: "test",
        informed_entities: commuter_rail_subscription_entities()
      }

      assert TextReplacement.replace_text!(alert, [sub]) == alert
    end

    test "if subscription matches alert, and has a different origin station, replace text" do
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
        header:
          "Newburyport Train 180 (9:25 pm from Newburyport) has departed Newburyport 20-40 minutes late and will operate at a reduced speed due to a mechanical issue.",
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
        ]
      }

      expected = %{
        header:
          "Newburyport Train 180 (10:17 pm from Chelsea) has departed Newburyport 20-40 minutes late and will operate at a reduced speed due to a mechanical issue.",
        description: "Affected trips: Newburyport Train 180 (10:17 pm from Chelsea)"
      }

      assert TextReplacement.replace_text!(alert, [sub]) == Map.merge(alert, expected)
    end

    test "if subscription matches alert and the origin station's id differs from its name, replace text" do
      sub = %Subscription{
        destination: "place-south",
        informed_entities: [
          %AlertProcessor.Model.InformedEntity{
            activities: ["BOARD"],
            stop: "Four Corners / Geneva"
          }
        ],
        origin: "Four Corners / Geneva"
      }

      alert = %Alert{
        description: "Affected trips: Fairmount Train 752 (9:25 PM from Fairmount)",
        header:
          "Fairmount Train 752 (9:25 pm from Fairmount) has departed Fairmount 20-40 minutes late and will operate at a reduced speed due to a mechanical issue.",
        id: "115346",
        informed_entities: [
          %InformedEntity{
            activities: ["BOARD", "EXIT", "RIDE"],
            route: "CR-Fairmount",
            route_type: 2,
            schedule: [
              %{
                departure_time: "2017-10-30T21:25:00-04:00",
                stop_id: "Fairmount",
                trip_id: "CR-Weekday-Aug14th-17-NR-180"
              },
              %{
                departure_time: "2017-10-30T22:17:00-04:00",
                stop_id: "Four Corners / Geneva",
                trip_id: "CR-Weekday-Aug14th-17-NR-180"
              },
              %{
                departure_time: "2017-10-30T22:28:00-04:00",
                stop_id: "South Station",
                trip_id: "CR-Weekday-Aug14th-17-NR-180"
              }
            ],
            trip: "180"
          }
        ]
      }

      expected = %{
        header:
          "Fairmount Train 752 (10:17 pm from Four Corners/Geneva) has departed Fairmount 20-40 minutes late and will operate at a reduced speed due to a mechanical issue.",
        description: "Affected trips: Fairmount Train 752 (10:17 pm from Four Corners/Geneva)"
      }

      assert TextReplacement.replace_text!(alert, [sub]) == Map.merge(alert, expected)
    end

    test "test that when an alert description contains multiple matches, only the first match is processed, Otherwise, the alerts text is duplicated." do
      sub = %Subscription{
        destination: "place-south",
        informed_entities: [
          %AlertProcessor.Model.InformedEntity{
            activities: ["BOARD"],
            stop: "Four Corners / Geneva"
          }
        ],
        origin: "Four Corners / Geneva"
      }

      alert = %Alert{
        header:
          "Fairmount Train 752 (9:25 PM from Fairmount) has departed Fairmount 20-40 minutes late and will operate at a reduced speed due to a mechanical issue.",
        description: """
        Affected trips: Fairmount Train 752 (9:25 PM from Fairmount)
        Fairmount Train 753 (10:05 PM from Fairmount)
        Fairmount Train 754 (10:45 PM from Fairmount)
        """,
        id: "115346",
        informed_entities: [
          %InformedEntity{
            activities: ["BOARD", "EXIT", "RIDE"],
            route: "CR-Fairmount",
            route_type: 2,
            schedule: [
              %{
                departure_time: "2017-10-30T21:25:00-04:00",
                stop_id: "Fairmount",
                trip_id: "CR-Weekday-Aug14th-17-NR-180"
              },
              %{
                departure_time: "2017-10-30T22:17:00-04:00",
                stop_id: "Four Corners / Geneva",
                trip_id: "CR-Weekday-Aug14th-17-NR-180"
              },
              %{
                departure_time: "2017-10-30T22:28:00-04:00",
                stop_id: "South Station",
                trip_id: "CR-Weekday-Aug14th-17-NR-180"
              }
            ],
            trip: "180"
          }
        ]
      }

      expected = %{
        header:
          "Fairmount Train 752 (10:17 pm from Four Corners/Geneva) has departed Fairmount 20-40 minutes late and will operate at a reduced speed due to a mechanical issue.",
        description: """
        Affected trips: Fairmount Train 752 (10:17 pm from Four Corners/Geneva)
        Fairmount Train 753 (10:05 PM from Fairmount)
        Fairmount Train 754 (10:45 PM from Fairmount)
        """
      }

      assert TextReplacement.replace_text!(alert, [sub]) == Map.merge(alert, expected)
    end
  end

  describe "replace_text/2" do
    test "returns :ok tuple with no errors" do
      alert = %Alert{}
      subscription = %Subscription{}

      assert {:ok, ^alert} = TextReplacement.replace_text(alert, [subscription])
    end

    test "returns :error tuple with invalid hour" do
      alert = %Alert{
        header: "Newburyport Train 180 (25:25 pm from Newburyport)",
        informed_entities: [%InformedEntity{route_type: 2}]
      }

      subscription = %Subscription{}

      assert {:error, _} = TextReplacement.replace_text(alert, [subscription])
    end
  end

  describe "parse_target/1" do
    test "when passed invalid parameters" do
      assert TextReplacement.parse_target(nil) == %{}
      assert TextReplacement.parse_target([]) == %{}
    end

    test "parses train 2-4 digit train numbers, with/wihout spaces" do
      first = "Lowell line 12(11:20am from Lowell)"
      second = "Lowell line 123(11:20am from Lowell)"
      third = "Lowell line 1234(11:20am from Lowell)"
      fourth = "Lowell line 123 (11:20am from Lowell)"

      assert TextReplacement.parse_target(first) == %{
               0 => {{"12", "Lowell", ~T[11:20:00]}, first}
             }

      assert TextReplacement.parse_target(second) == %{
               0 => {{"123", "Lowell", ~T[11:20:00]}, second}
             }

      assert TextReplacement.parse_target(third) == %{
               0 => {{"1234", "Lowell", ~T[11:20:00]}, third}
             }

      assert TextReplacement.parse_target(fourth) == %{
               0 => {{"123", "Lowell", ~T[11:20:00]}, fourth}
             }
    end

    test "parses time with different AM/PM combinations" do
      first = "Lowell line 12 (11:20am from Lowell)"
      second = "Lowell line 12 (11:20 AM from Lowell)"
      third = "Lowell line 12 (11:20 PM from Lowell)"
      fourth = "Lowell line 12 (11:20PM from Lowell)"

      assert TextReplacement.parse_target(first) == %{
               0 => {{"12", "Lowell", ~T[11:20:00]}, first}
             }

      assert TextReplacement.parse_target(second) == %{
               0 => {{"12", "Lowell", ~T[11:20:00]}, second}
             }

      assert TextReplacement.parse_target(third) == %{
               0 => {{"12", "Lowell", ~T[23:20:00]}, third}
             }

      assert TextReplacement.parse_target(fourth) == %{
               0 => {{"12", "Lowell", ~T[23:20:00]}, fourth}
             }
    end

    test "parses time for all hours of the day" do
      expected = %{
        "12:00am" => ~T[00:00:00],
        "1:00am" => ~T[01:00:00],
        "2:00am" => ~T[02:00:00],
        "3:00am" => ~T[03:00:00],
        "4:00am" => ~T[04:00:00],
        "5:00am" => ~T[05:00:00],
        "6:00am" => ~T[06:00:00],
        "7:00am" => ~T[07:00:00],
        "8:00am" => ~T[08:00:00],
        "9:00am" => ~T[09:00:00],
        "10:00am" => ~T[10:00:00],
        "11:00am" => ~T[11:00:00],
        "12:00pm" => ~T[12:00:00],
        "1:00pm" => ~T[13:00:00],
        "2:00pm" => ~T[14:00:00],
        "3:00pm" => ~T[15:00:00],
        "4:00pm" => ~T[16:00:00],
        "5:00pm" => ~T[17:00:00],
        "6:00pm" => ~T[18:00:00],
        "7:00pm" => ~T[19:00:00],
        "8:00pm" => ~T[20:00:00],
        "9:00pm" => ~T[21:00:00],
        "10:00pm" => ~T[22:00:00],
        "11:00pm" => ~T[23:00:00]
      }

      for hour <- 1..12, am_pm <- ["am", "pm"] do
        time = "#{hour}:00#{am_pm}"
        text = "Lowell line 12 (#{time} from Lowell)"
        %{0 => {{_, _, time_result}, _}} = TextReplacement.parse_target(text)
        assert time_result == Map.get(expected, time)
      end
    end

    test "parse station" do
      first = "Lowell line 12 (11:20am from Anderson/Woburn)"
      second = "Lowell line 12 (11:20am from Lowell)"
      third = "Lowell line 12 (11:20am from Anderson / Woburn)"
      fourth = "Lowell line 12 (11:20am from Anderson/ Woburn)"

      assert TextReplacement.parse_target(first) == %{
               0 => {{"12", "Anderson/Woburn", ~T[11:20:00]}, first}
             }

      assert TextReplacement.parse_target(second) == %{
               0 => {{"12", "Lowell", ~T[11:20:00]}, second}
             }

      assert TextReplacement.parse_target(third) == %{
               0 => {{"12", "Anderson / Woburn", ~T[11:20:00]}, third}
             }

      assert TextReplacement.parse_target(fourth) == %{
               0 => {{"12", "Anderson/ Woburn", ~T[11:20:00]}, fourth}
             }
    end

    test "parses multiple matches" do
      text =
        "Lowell line 12 (11:20am from Anderson/Woburn) and Rockport line 456 (2:30pm from South Station)"

      assert TextReplacement.parse_target(text) == %{
               0 => {{"12", "Anderson/Woburn", ~T[11:20:00]}, text},
               1 => {{"456", "South Station", ~T[14:30:00]}, text}
             }
    end
  end
end
