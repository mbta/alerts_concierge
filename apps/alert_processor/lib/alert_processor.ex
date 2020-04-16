defmodule AlertProcessor do
  @moduledoc "Application bootstrap"
  use Application
  def start(), do: start(nil, nil)

  def start(_type, _args) do
    link = AlertProcessor.Supervisor.start_link()
    Application.get_env(:alert_processor, :migration_task).migrate()
    :hackney_trace.enable(:max, :io)
    link
  end
end
