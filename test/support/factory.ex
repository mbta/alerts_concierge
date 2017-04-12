defmodule MbtaServer.Factory do
  use ExMachina.Ecto, repo: MbtaServer.Repo

  def informed_entity_factory do
    %MbtaServer.InformedEntity{}
  end

  def subscription_factory do
    %MbtaServer.Subscription{
      alert_types: [],
      priority: "High",
      travel_days: []
    }
  end

  def user_factory do
    %MbtaServer.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      phone_number: sequence(:phone_number, &(String.pad_leading("#{&1}", 12, "+15555551234"))),
      role: "user"
    }
  end
end
