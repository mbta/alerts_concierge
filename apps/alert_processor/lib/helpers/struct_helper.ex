defmodule AlertProcessor.Helpers.StructHelper do
  @moduledoc """
  Helper functions for converting maps to structs
  """

  @doc """
  This function is used for converting the map of change data
  from PaperTrail versions into a struct of the object. Since PaperTrail
  converts all attribute keys to strings, this function converts them
  back to atoms
  """
  def to_struct(kind, attrs) do
    struct = struct(kind)
    Enum.reduce Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end
  end
end
