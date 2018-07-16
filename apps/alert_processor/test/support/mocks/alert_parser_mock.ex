defmodule AlertProcessor.AlertParserMock do
  @moduledoc """
  Module to act as mock implementation for AlertParser
  for testing purposes.
  """

  alias AlertProcessor.Parser

  @behaviour Parser

  @doc """
  process_alerts/1 send messages to self for tests to be able
  to verify that process_alerts has properly been called.
  """
  def process_alerts(:older) do
    send_to_self()
  end

  def process_alerts(:recent) do
    send_to_self()
  end

  def process_alerts(:anytime) do
    send_to_self()
  end

  def process_alerts() do
    send_to_self()
  end

  defp send_to_self do
    send self(), :processed_alerts
    [{:ok, []}]
  end
end
