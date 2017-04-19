defmodule MbtaServer.Factory do
  use ExMachina.Ecto, repo: MbtaServer.Repo

  alias MbtaServer.User
  alias MbtaServer.AlertProcessor.Model.{InformedEntity, Subscription}

  def informed_entity_factory do
    %InformedEntity{}
  end

  def subscription_factory do
    %Subscription{}
  end

  def user_factory do
    %User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      phone_number: sequence(:phone_number, &(String.pad_leading("#{&1}", 12, "+15555551234"))),
      role: "user"
    }
  end
end
