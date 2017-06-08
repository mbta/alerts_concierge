defmodule AlertProcessor.AtomArrayType do
  @moduledoc """
  Atom type for Ecto
  """
  @behaviour Ecto.Type
  def type, do: {:array, AlertProcessor.AtomType}
  def cast(value) when is_list(value) do
    {:ok, Enum.map(value, fn(x) -> {:array, x} end)}
  end
  def load(value) when is_list(value), do: {:ok, Enum.map(value, fn(x) -> String.to_existing_atom(x) end)}
  def dump(value) when is_list(value) do
    {:ok,
      Enum.map(value, fn(val) ->
        case val do
          {:array, x} ->
            cond do
              is_atom(x) -> Atom.to_string(x)
              true -> x
            end
          x ->
           cond do
             is_atom(x) -> Atom.to_string(x)
             true -> x
           end
        end
      end)
    }
  end
  def dump(_), do: :error
end
