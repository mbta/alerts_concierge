defmodule AlertProcessor do
  @moduledoc "Application bootstrap"
  use Application
  def start(), do: start(nil, nil)
  def start(_type, _args) do
    AlertProcessor.Supervisor.start_link()
  end
end
