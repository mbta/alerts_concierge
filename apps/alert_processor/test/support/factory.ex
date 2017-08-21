defmodule AlertProcessor.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: AlertProcessor.Repo

  alias AlertProcessor.Model.{InformedEntity, Notification, Subscription, User, PasswordReset}
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
      start_time: ~T[14:00:00],
      end_time: ~T[18:00:00]
    }
  end

  def admin_subscription_factory do
    %Subscription{
      relevant_days: [:weekday, :saturday, :sunday],
      alert_priority_type: :low,
      start_time: ~T[00:00:00],
      end_time: ~T[23:59:59]
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
      origin: "Davis",
      destination: "Harvard"}
  end

  def subway_subscription_entities() do
    [
      %InformedEntity{route_type: 1},
      %InformedEntity{route_type: 1, route: "Red"},
      %InformedEntity{route_type: 1, route: "Red", direction_id: 0},
      %InformedEntity{route_type: 1, route: "Red", stop: "place-davis"},
      %InformedEntity{route_type: 1, route: "Red", stop: "place-harsq"}
    ]
  end

  def bus_subscription(%Subscription{} = subscription) do
    %{subscription |
      type: :bus
    }
  end

  def bus_subscription_entities() do
    [
      %InformedEntity{route_type: 3},
      %InformedEntity{route_type: 3, route: "57A"},
      %InformedEntity{route_type: 3, route: "57A", direction_id: 0}
    ]
  end

  def commuter_rail_subscription(%Subscription{} = subscription) do
    %{subscription |
      type: :commuter_rail,
      origin: "North Station",
      destination: "Anderson/Woburn"
    }
  end

  def commuter_rail_subscription_entities() do
    [
      %InformedEntity{route_type: 2},
      %InformedEntity{trip: "221"},
      %InformedEntity{trip: "331"},
      %InformedEntity{route_type: 2, route: "CR-Lowell", direction_id: 1},
      %InformedEntity{route_type: 2, route: "CR-Lowell", stop: "Anderson/ Woburn"},
      %InformedEntity{route_type: 2, route: "CR-Lowell", stop: "place-north"}
    ]
  end

  def ferry_subscription(%Subscription{} = subscription) do
    %{subscription |
      type: :ferry,
      origin: "Long Wharf, Boston",
      destination: "Charlestown Navy Yard"
    }
  end

  def ferry_subscription_entities() do
    [
      %InformedEntity{route_type: 4},
      %InformedEntity{trip: "Boat-F4-Boat-Long-17:15:00-weekday-0"},
      %InformedEntity{trip: "Boat-F4-Boat-Long-17:00:00-weekday-0"},
      %InformedEntity{route_type: 4, route: "Boat-F4", direction_id: 1},
      %InformedEntity{route_type: 4, route: "Boat-F4", stop: "Boat-Charlestown"},
      %InformedEntity{route_type: 4, route: "Boat-F4", stop: "Boat-Long"}
    ]
  end

  def amenity_subscription(%Subscription{} = subscription) do
    %{subscription |
      alert_priority_type: :low,
      type: :amenity
     }
  end

  def amenity_subscription_entities() do
    [
      %InformedEntity{route_type: 4, facility_type: :elevator, route: "Green"},
      %InformedEntity{route_type: 4, facility_type: :escalator, stop: "place-nqncy"}
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
end
