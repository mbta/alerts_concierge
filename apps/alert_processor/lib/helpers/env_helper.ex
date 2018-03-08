defmodule AlertProcessor.Helpers.EnvHelper do

  def mix_is_loaded? do
    Code.ensure_loaded?(Mix)
  end

  def is_env?(env_name) do
    mix_is_loaded? && Mix.env() == env_name
  end

  def env do
    if mix_is_loaded? do
      Mix.env()
    end
  end

end