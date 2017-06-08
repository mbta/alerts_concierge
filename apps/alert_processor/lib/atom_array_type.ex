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
        value =
          case val do
            {:array, x} -> x
            x -> x
          end

        if is_atom(value) do
          Atom.to_string(value)
        else
          value
        end
      end)
    }
  end
  def dump(_), do: :error
end
