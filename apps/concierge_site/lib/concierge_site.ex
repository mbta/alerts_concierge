defmodule ConciergeSite do
  @moduledoc "Application for Alert Concierge frontend"
  use Application

  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: ConciergeSite.PubSub},
      {ConciergeSite.Plugs.RateLimit.Backend,
       [clean_period: to_timeout(minute: 10), key_older_than: to_timeout(hour: 4)]},
      ConciergeSite.Endpoint,
      Guardian.DB.Token.SweeperServer
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
