defmodule ConciergeSite.Logster.SafeStringFormatter do
  @moduledoc """
  Version of Logster.StringFormatter which doesn't crash on values which
  aren't representable in JSON.
  """
  def format(params) do
    params
    |> Enum.map(&format_field/1)
    |> Enum.intersperse(?\s)
  end

  defp format_field({key, value}) do
    [to_string(key), "=", format_value(value)]
  end

  defp format_value(value) when is_binary(value) do
    value
  end

  defp format_value(value) when is_float(value) do
    :erlang.float_to_binary(value, [decimals: 3])
  end

  defp format_value(value) when is_atom(value) or is_integer(value) do
    to_string(value)
  end

  defp format_value(value) when is_map(value) do
    Poison.encode_to_iodata!(value)
  rescue
    _error ->
      inspect(value)
  end
end
