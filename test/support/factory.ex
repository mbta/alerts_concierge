defmodule MbtaServer.Factory do
  use ExMachina.Ecto, repo: MbtaServer.Repo

  def user_factory do
    %MbtaServer.User{
      email: sequence(:email, &"email-#{&1}@example.com"),
      phone_number: sequence(:phone_number, &(String.pad_leading("#{&1}", 12, "+15555551234"))),
      role: "user"
    }
  end
end
