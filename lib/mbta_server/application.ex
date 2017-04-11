defmodule MbtaServer.Application do
  @moduledoc "Application bootstrap"
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(MbtaServer.Repo, []),
      # Start the endpoint when the application starts
      supervisor(MbtaServer.Web.Endpoint, []),
      supervisor(MbtaServer.AlertProcessor, [])
    ]
    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MbtaServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
