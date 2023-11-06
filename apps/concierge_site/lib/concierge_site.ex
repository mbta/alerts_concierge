defmodule ConciergeSite do
  @moduledoc "Application for Alert Concierge frontend"
  use Application

  def start(_type, _args) do
    auth_children =
      if Application.get_env(:concierge_site, :start_oidc_worker) do
        [
          {OpenIDConnect.Worker, Application.get_env(:ueberauth, Ueberauth.Strategy.OIDC)}
        ]
      else
        []
      end

    children =
      auth_children ++
        [
          {Phoenix.PubSub, name: ConciergeSite.PubSub},
          ConciergeSite.Endpoint,
          Guardian.DB.Token.SweeperServer
        ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
