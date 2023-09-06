defmodule Helpers.RuntimeHelper do
  @moduledoc """
  Helper functions for defining runtime configuration.
  """

  @spec module_from_string_or_default(String.t() | nil, module()) :: module()
  def module_from_string_or_default(nil, default), do: default

  def module_from_string_or_default(mod_str, _) when is_binary(mod_str),
    do: String.to_atom("Elixir.#{mod_str}")
end
