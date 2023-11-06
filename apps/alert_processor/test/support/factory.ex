defmodule AlertProcessor.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: AlertProcessor.Repo

  alias AlertProcessor.Model.{
    InformedEntity,
    Notification,
    Subscription,
    User,
    Trip,
    NotificationSubscription,
    SavedAlert
  }

  def informed_entity_factory do
    %InformedEntity{}
  end

  def notification_factory do
    %Notification{
      service_effect: "Test Message",
      header: "Test Message",
      description: "Test Message"
    }
  end

  def subscription_factory do
    %Subscription{
      relevant_days: [],
      start_time: ~T[10:00:00],
      end_time: ~T[14:00:00]
    }
  end

  def weekday_subscription(%Subscription{} = subscription) do
    Map.put(subscription, :relevant_days, [:weekday | subscription.relevant_days])
  end

  def sunday_subscription(%Subscription{} = subscription) do
    Map.put(subscription, :relevant_days, [:sunday | subscription.relevant_days])
  end

  def saturday_subscription(%Subscription{} = subscription) do
    Map.put(subscription, :relevant_days, [:saturday | subscription.relevant_days])
  end

  def subway_subscription(%Subscription{} = subscription) do
    %{subscription | type: :subway, origin: "place-davis", destination: "place-harsq"}
  end

  def subway_subscription_entities() do
    [
      %InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{
        route_type: 1,
        route: "Red",
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route_type: 1,
        route: "Red",
        direction_id: 0,
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{route_type: 1, route: "Red", stop: "place-davis", activities: ["BOARD"]},
      %InformedEntity{route_type: 1, route: "Red", stop: "place-portr", activities: ["RIDE"]},
      %InformedEntity{route_type: 1, route: "Red", stop: "place-harsq", activities: ["EXIT"]}
    ]
  end

  def roaming_subway_subscription_entities() do
    [
      %InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{
        route_type: 1,
        route: "Red",
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route_type: 1,
        route: "Red",
        direction_id: 0,
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route_type: 1,
        route: "Red",
        direction_id: 1,
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route_type: 1,
        route: "Red",
        stop: "place-davis",
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route_type: 1,
        route: "Red",
        stop: "place-portr",
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route_type: 1,
        route: "Red",
        stop: "place-harsq",
        activities: InformedEntity.default_entity_activities()
      }
    ]
  end

  def bus_subscription(%Subscription{} = subscription) do
    %{subscription | type: :bus}
  end

  def bus_subscription_entities(route \\ "57A"), do: bus_subscription_entities(route, 0)
  def bus_subscription_entities(route, :inbound), do: bus_subscription_entities(route, 1)
  def bus_subscription_entities(route, :outbound), do: bus_subscription_entities(route, 0)

  def bus_subscription_entities(route, direction_id) do
    [
      %InformedEntity{route_type: 3, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{
        route_type: 3,
        route: route,
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route_type: 3,
        route: route,
        direction_id: direction_id,
        activities: InformedEntity.default_entity_activities()
      }
    ]
  end

  def commuter_rail_subscription(%Subscription{} = subscription) do
    %{subscription | type: :commuter_rail, origin: "place-north", destination: "place-NHRML-0127"}
  end

  def commuter_rail_subscription_entities() do
    [
      %InformedEntity{route_type: 2, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{trip: "221", activities: InformedEntity.default_entity_activities()},
      %InformedEntity{trip: "331", activities: InformedEntity.default_entity_activities()},
      %InformedEntity{
        route_type: 2,
        route: "CR-Lowell",
        direction_id: 1,
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route_type: 2,
        route: "CR-Lowell",
        stop: "place-NHRML-0127",
        activities: ["BOARD"]
      },
      %InformedEntity{
        route_type: 2,
        route: "CR-Lowell",
        stop: "place-north",
        activities: ["EXIT"]
      }
    ]
  end

  def ferry_subscription(%Subscription{} = subscription) do
    %{subscription | type: :ferry, origin: "Boat-Long", destination: "Boat-Charlestown"}
  end

  def ferry_subscription_entities() do
    [
      %InformedEntity{route_type: 4, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{
        trip: "Boat-F4-Boat-Long-17:15:00-weekday-0",
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        trip: "Boat-F4-Boat-Long-17:00:00-weekday-0",
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route_type: 4,
        route: "Boat-F4",
        direction_id: 1,
        activities: InformedEntity.default_entity_activities()
      },
      %InformedEntity{
        route_type: 4,
        route: "Boat-F4",
        stop: "Boat-Charlestown",
        activities: ["BOARD"]
      },
      %InformedEntity{route_type: 4, route: "Boat-F4", stop: "Boat-Long", activities: ["EXIT"]}
    ]
  end

  def accessibility_subscription(%Subscription{} = subscription) do
    %{subscription | type: :accessibility}
  end

  def accessibility_subscription_entities() do
    [
      %InformedEntity{route_type: 4, facility_type: :elevator, route: "Green"},
      %InformedEntity{route_type: 4, facility_type: :escalator, stop: "place-nqncy"}
    ]
  end

  def parking_subscription(%Subscription{} = subscription) do
    %{subscription | type: :parking}
  end

  def parking_subscription_entities() do
    [
      %InformedEntity{route_type: 4, facility_type: :parking_area, route: "Green"},
      %InformedEntity{route_type: 4, facility_type: :parking_area, stop: "place-nqncy"}
    ]
  end

  def bike_storage_subscription(%Subscription{} = subscription) do
    %{subscription | type: :bike_storage}
  end

  def bike_storage_subscription_entities() do
    [
      %InformedEntity{route_type: 4, facility_type: :bike_storage, route: "Green"},
      %InformedEntity{route_type: 4, facility_type: :bike_storage, stop: "place-nqncy"}
    ]
  end

  def user_factory do
    %User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      phone_number: sequence(:phone_number, &String.pad_leading("#{&1}", 10, "5555551234")),
      role: "user"
    }
  end

  def trip_factory do
    %Trip{
      relevant_days: [:monday],
      start_time: ~T[11:00:00],
      end_time: ~T[18:00:00],
      facility_types: [:elevator],
      user: build(:user)
    }
  end

  def notification_subscription_factory do
    %NotificationSubscription{}
  end

  def saved_alert_factory do
    %SavedAlert{
      alert_id: "119076",
      data: %{
        "active_period" => [%{"end" => 1_538_162_074, "start" => 1_538_154_825}],
        "alert_lifecycle" => "NEW",
        "cause" => "TECHNICAL_PROBLEM",
        "cause_detail" => "SIGNAL_PROBLEM",
        "created_timestamp" => 1_538_154_830,
        "description_text" => %{
          "translation" => [%{"language" => "en", "text" => ""}]
        },
        "duration_certainty" => "ESTIMATED",
        "effect" => "OTHER_EFFECT",
        "effect_detail" => "DELAY",
        "header_text" => %{
          "translation" => [
            %{
              "language" => "en",
              "text" =>
                "TEST Red Line experiencing delays of up to 10 minutes due to signal problem"
            }
          ]
        },
        "id" => "119076",
        "informed_entity" => [
          %{
            "activities" => ["BOARD", "EXIT", "RIDE"],
            "route_id" => "Red",
            "route_type" => 1
          },
          %{
            "activities" => ["BOARD", "EXIT", "RIDE"],
            "route_id" => "215",
            "route_type" => 3
          },
          %{
            "activities" => ["BOARD", "EXIT", "RIDE"],
            "route_id" => "CR-Providence",
            "route_type" => 2,
            "stop_id" => "place-SB-0156"
          }
        ],
        "last_modified_timestamp" => 1_538_154_830,
        "last_push_notification_timestamp" => 1_538_154_830,
        "service_effect_text" => %{
          "translation" => [%{"language" => "en", "text" => "Red Line delay"}]
        },
        "severity" => 3,
        "short_header_text" => %{
          "translation" => [
            %{
              "language" => "en",
              "text" =>
                "TEST Red Line experiencing delays of up to 10 minutes due to signal problem"
            }
          ]
        }
      },
      id: "500aac16-1cda-4fb9-b64c-1be9ff7336b4",
      inserted_at: ~N[2018-09-28 17:16:59.036670],
      notification_type: nil,
      updated_at: ~N[2018-09-28 17:16:59.036681]
    }
  end
end
