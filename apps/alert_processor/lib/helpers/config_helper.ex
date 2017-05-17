defmodule AlertProcessor.Helpers.ConfigHelper do
  @moduledoc """
  Module for getting config vars which handles the
  {:system, env, default} format.
  """

  @spec get(atom, atom) :: String.t | integer
  def get(name) do
    do_get(name)
  end

  def get(name, :int) do
    name |> do_get() |> String.to_integer()
  end

  defp do_get(name) do
    case Application.get_env(:alert_processor, name) do
      {:system, env_var, default} -> System.get_env(env_var) || default
      value -> value
    end
  end
end
