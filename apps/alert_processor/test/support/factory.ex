defmodule AlertProcessor.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: AlertProcessor.Repo

  alias AlertProcessor.Model.{InformedEntity, Notification, Subscription, User}

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

  def user_factory do
    %User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      phone_number: sequence(:phone_number, &(String.pad_leading("#{&1}", 10, "5555551234"))),
      role: "user",
      encrypted_password: sequence(:encrypted_password, &"encrypted_password_#{&1}")
    }
  end
end
