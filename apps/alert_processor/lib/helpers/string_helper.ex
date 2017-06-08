defmodule AlertProcessor.Helpers.StringHelper do
  @moduledoc """
  Module containing reusable string helpers
  """

  @doc """
  or_join takes an array of strings and concats with commas and
  adds an or before the last word. Will only join with a single or
  and no commas for 2 words.
  """
  @spec or_join([String.t]) :: String.t
  def or_join(str \\ "", words)
  def or_join(str, []), do: str
  def or_join("", [str]), do: str
  def or_join("", [x, y]), do: "#{x} or #{y}"
  def or_join(str, [h]) do
    "#{str}, or #{h}"
  end
  def or_join("", [h | t]) do
    or_join(h, t)
  end
  def or_join(str, [h | t]) do
    or_join("#{str}, #{h}", t)
  end
end
