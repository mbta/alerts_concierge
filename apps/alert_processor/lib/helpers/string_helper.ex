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

  @doc """
  Takes a string and capitalizes only the first character without doing anything
  to the remaining characters
  """
  @spec capitalize_first(String.t) :: String.t
  def capitalize_first(<< first_character :: binary-1, rest :: binary >>),
   do: String.upcase(first_character) <> rest

  @doc """
  split_capitalize takes a string and optional split string and returns
  the string split and joined with a space with each word capitalized.
  """
  @spec split_capitalize(String.t) :: String.t
  def split_capitalize(str, split \\ " ") do
    str |> String.split(split) |> Enum.map_join(" ", &String.capitalize/1)
  end
end
