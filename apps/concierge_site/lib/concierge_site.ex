defmodule ConciergeSite do
  @moduledoc "Application for Alert Concierge frontend"
  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(ConciergeSite.Endpoint, []),
      # Start your own worker by calling: ConciergeSite.Worker.start_link(arg1, arg2, arg3)
      # worker(ConciergeSite.Worker, [arg1, arg2, arg3]),
      worker(ConciergeSite.Dissemination.MailerInterface, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
