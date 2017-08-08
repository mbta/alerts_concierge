defmodule AlertProcessor do
  @moduledoc "Application bootstrap"
  use Application
  def start(), do: start(nil, nil)
  def start(_type, _args) do
    if System.get_env("MIX_ENV") == "prod" do
      AlertProcessor.RuntimeConfig.set_runtime_config()
    end
    AlertProcessor.Supervisor.start_link()
  end
end
