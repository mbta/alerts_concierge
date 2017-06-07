defmodule AlertProcessor.Helpers.StringHelper do
  def or_join(str \\ "", words)
  def or_join(str, []), do: str
  def or_join("", [str]), do: str
  def or_join("", [x, y]), do: "#{x} or #{y}"
  def or_join(str, [h | []]) do
    "#{str}, or #{h}"
  end
  def or_join("", [h | t]) do
    or_join(h, t)
  end
  def or_join(str, [h | t]) do
    or_join("#{str}, #{h}", t)
  end
end
