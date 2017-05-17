defmodule AlertProcessor.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: AlertProcessor.Repo

  alias AlertProcessor.Model.{InformedEntity, Notification, Subscription, User}

  def informed_entity_factory do
    %InformedEntity{}
  end

  def notification_factory do
    %Notification{
      message: "Test Message",
      header: "Test Message"
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

  def user_factory do
    %User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      phone_number: sequence(:phone_number, &(String.pad_leading("#{&1}", 12, "+15555551234"))),
      role: "user",
      encrypted_password: "abc123"
    }
  end
end
