defmodule MbtaServer.Factory do
  use ExMachina.Ecto, repo: MbtaServer.Repo

  alias MbtaServer.User
  alias MbtaServer.AlertProcessor.Model.{InformedEntity, Notification, Subscription}

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
      alert_priority_type: :medium
    }
  end

  def user_factory do
    %User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      phone_number: sequence(:phone_number, &(String.pad_leading("#{&1}", 12, "+15555551234"))),
      role: "user",
      do_not_disturb_start: ~T[23:59:00.000],
      do_not_disturb_end: ~T[01:00:00.000],
      vacation_start: "2015-10-22T04:30:00-04:00",
      vacation_end: "2015-10-22T04:30:00-04:00"
    }
  end
end
