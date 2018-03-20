defmodule AlertProcessor.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: AlertProcessor.Repo

  alias AlertProcessor.Model.{InformedEntity, Notification, Subscription, User, PasswordReset, Trip}
  alias Calendar.DateTime

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
      alert_priority_type: :medium,
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
    %{subscription |
      type: :subway,
      origin: "place-davis",
      destination: "place-harsq"}
  end

  def subway_subscription_entities() do
    [
      %InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 1, route: "Red", activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 1, route: "Red", direction_id: 0, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 1, route: "Red", stop: "place-davis", activities: ["BOARD"]},
      %InformedEntity{route_type: 1, route: "Red", stop: "place-portr", activities: ["RIDE"]},
      %InformedEntity{route_type: 1, route: "Red", stop: "place-harsq", activities: ["EXIT"]}
    ]
  end

  def roaming_subway_subscription_entities() do
    [
      %InformedEntity{route_type: 1, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 1, route: "Red", activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 1, route: "Red", direction_id: 0, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 1, route: "Red", direction_id: 1, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 1, route: "Red", stop: "place-davis", activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 1, route: "Red", stop: "place-portr", activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 1, route: "Red", stop: "place-harsq", activities: InformedEntity.default_entity_activities()}
    ]
  end

  def bus_subscription(%Subscription{} = subscription) do
    %{subscription |
      type: :bus
    }
  end

  def bus_subscription_entities(route \\ "57A"), do: bus_subscription_entities(route, 0)
  def bus_subscription_entities(route, :inbound), do: bus_subscription_entities(route, 1)
  def bus_subscription_entities(route, :outbound), do: bus_subscription_entities(route, 0)
  def bus_subscription_entities(route, direction_id) do
    [
      %InformedEntity{route_type: 3, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 3, route: route, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 3, route: route, direction_id: direction_id, activities: InformedEntity.default_entity_activities()}
    ]
  end

  def commuter_rail_subscription(%Subscription{} = subscription) do
    %{subscription |
      type: :commuter_rail,
      origin: "place-north",
      destination: "Anderson/ Woburn"
    }
  end

  def commuter_rail_subscription_entities() do
    [
      %InformedEntity{route_type: 2, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{trip: "221", activities: InformedEntity.default_entity_activities()},
      %InformedEntity{trip: "331", activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 2, route: "CR-Lowell", direction_id: 1, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 2, route: "CR-Lowell", stop: "Anderson/ Woburn", activities: ["BOARD"]},
      %InformedEntity{route_type: 2, route: "CR-Lowell", stop: "place-north", activities: ["EXIT"]}
    ]
  end

  def ferry_subscription(%Subscription{} = subscription) do
    %{subscription |
      type: :ferry,
      origin: "Boat-Long",
      destination: "Boat-Charlestown"
    }
  end

  def ferry_subscription_entities() do
    [
      %InformedEntity{route_type: 4, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{trip: "Boat-F4-Boat-Long-17:15:00-weekday-0", activities: InformedEntity.default_entity_activities()},
      %InformedEntity{trip: "Boat-F4-Boat-Long-17:00:00-weekday-0", activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 4, route: "Boat-F4", direction_id: 1, activities: InformedEntity.default_entity_activities()},
      %InformedEntity{route_type: 4, route: "Boat-F4", stop: "Boat-Charlestown", activities: ["BOARD"]},
      %InformedEntity{route_type: 4, route: "Boat-F4", stop: "Boat-Long", activities: ["EXIT"]}
    ]
  end

  def accessibility_subscription(%Subscription{} = subscription) do
    %{subscription |
      alert_priority_type: :low,
      type: :accessibility
     }
  end

  def accessibility_subscription_entities() do
    [
      %InformedEntity{route_type: 4, facility_type: :elevator, route: "Green"},
      %InformedEntity{route_type: 4, facility_type: :escalator, stop: "place-nqncy"}
    ]
  end

  def parking_subscription(%Subscription{} = subscription) do
    %{subscription |
      alert_priority_type: :low,
      type: :parking
     }
  end

  def parking_subscription_entities() do
    [
      %InformedEntity{route_type: 4, facility_type: :parking_area, route: "Green"},
      %InformedEntity{route_type: 4, facility_type: :parking_area, stop: "place-nqncy"}
    ]
  end

  def bike_storage_subscription(%Subscription{} = subscription) do
    %{subscription |
      alert_priority_type: :low,
      type: :bike_storage
     }
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
      phone_number: sequence(:phone_number, &(String.pad_leading("#{&1}", 10, "5555551234"))),
      role: "user",
      encrypted_password: sequence(:encrypted_password, &"encrypted_password_#{&1}")
    }
  end

  def password_reset_factory do
    %PasswordReset{
      expired_at: DateTime.add!(DateTime.now_utc, 3600),
      redeemed_at: nil,
      user: build(:user)
    }
  end

  def trip_factory do
    %Trip{
      alert_priority_type: :low,
      relevant_days: [:monday],
      start_time: ~T[12:00:00],
      end_time: ~T[18:00:00],
      notification_time: ~T[11:00:00],
      station_features: [:accessibility]
    }
  end
end
