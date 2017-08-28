defmodule SystemMetrics.Testmeter do
  @moduledoc """
  A module for mocking elixometer in tests
  """

  @doc """
  Proxy elixometer's update_gauge function
  """
  @spec update_gauge(String.t, integer) :: :ok
  def update_gauge(label, value) do
    put({:gauge, label}, value)
  end

  @doc """
  Proxy elixometer's update_histogram function
  """
  @spec update_histogram(String.t, integer) :: :ok
  def update_histogram(label, value) do
    put({:histogram, label}, value)
  end

  @doc """
  Proxy elixometer's update_counter function
  """
  @spec update_counter(String.t, integer, []) :: :ok
  def update_counter(label, value, _options) do
    put({:counter, label}, value)
  end

  @doc """
  start the agent process
  """
  @spec start_link() :: {atom, pid}
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  clear all stored data
  """
  @spec clear() :: :ok
  def clear do
    Agent.update(__MODULE__, fn _state -> %{} end)
  end

  @doc """
  output all the data
  """
  @spec dump() :: map
  def dump do
    Agent.get(__MODULE__, fn state -> state end)
  end

  @spec put({:gauge | :histogram | :counter, String.t}, integer) :: :ok
  defp put(label, value) do
    # Helper function to make the code more dry
    Agent.update(__MODULE__, fn state -> Map.put(state, label, value) end)
  end
end
