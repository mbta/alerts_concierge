defmodule AlertProcessor.Helpers.ConfigHelper do
  @moduledoc """
  Module for getting config vars which handles the
  {:system, env, default} format.
  """

  @spec get_string(atom, atom) :: String.t() | integer | nil
  def get_string(name, app \\ :alert_processor) do
    do_get(name, app)
  end

  @spec get_int(atom, atom) :: String.t() | integer
  def get_int(name, app \\ :alert_processor) do
    name |> do_get(app) |> String.to_integer()
  end

  defp do_get(name, app) do
    case Application.get_env(app, name) do
      {:system, env_var, default} -> System.get_env(env_var) || default
      {:system, env_var} -> System.get_env(env_var) || raise "missing env var: #{env_var}"
      value -> value
    end
  end
end
