defmodule ConciergeSite do
  @moduledoc "Application for Alert Concierge frontend"
  use Application

  def start(_type, _args) do
    children = [
      ConciergeSite.Endpoint,
      Guardian.DB.Token.SweeperServer
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
