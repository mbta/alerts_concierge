defmodule MbtaServer.Repo do
  use Ecto.Repo, otp_app: :mbta_server
  @dialyzer {:nowarn_function, rollback: 1}
end
