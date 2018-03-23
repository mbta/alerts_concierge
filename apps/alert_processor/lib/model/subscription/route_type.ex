defmodule AlertProcessor.Model.Subscription.RouteType do
  @moduledoc """
  This module is for conversion of `route_type` integers into
  meaningful, human-intelligible names.
  """
  @numbers_to_names %{
    0 => :light_rail,
    1 => :heavy_rail,
    2 => :commuter_rail,
    3 => :bus,
    4 => :ferry,
  }

  @doc """
  Turns a number into a name (atom) or nil.

  iex> RouteType.number_to_name(0)
  :light_rail

  iex> RouteType.number_to_name(1)
  :heavy_rail

  iex> RouteType.number_to_name(2)
  :commuter_rail

  iex> RouteType.number_to_name(3)
  :bus

  iex> RouteType.number_to_name(4)
  :ferry

  iex> RouteType.number_to_name(-1)
  nil
  """
  def number_to_name(num) when is_integer(num) do
    Map.get(@numbers_to_names, num)
  end
  def number_to_name(_) do
    nil
  end

  @doc """
  Turns a name into a number that represent a route_type's name.

  iex> RouteType.name_to_number(:subway)
  0

  iex> RouteType.name_to_number(:light_rail)
  0

  iex> RouteType.name_to_number(:ferry)
  4

  iex> RouteType.name_to_number(:other)
  nil
  """
  def name_to_number(:subway) do
    0  
  end
  def name_to_number(name) when is_atom(name) do
    @numbers_to_names
    |> Enum.find(fn {_, transport_name} -> name == transport_name end)
    |> case do
      nil ->
        nil
      {num, _} when is_integer(num) ->
        num
    end  
  end
  def name_to_number(_) do
    nil
  end
  
end