defmodule AlertProcessor.RuntimeConfig do
  @moduledoc "Set runtime config for deps that can't be set in config.exs"

  def set_runtime_config do
    set_logentries()
  end

  defp set_logentries do
    env = Enum.into(Application.get_env(:logger, :logentries), %{})
    token = System.get_env("LOGENTRIES_TOKEN")
    new_env = Map.put(env, :token, token)
    Application.put_env(:logger, :logentries, new_env)
  end
end
