defmodule MbtaServer.AlertProcessor.AlertParserMock do
  @moduledoc """
  Module to act as mock implementation for AlertParser
  for testing purposes.
  """

  alias MbtaServer.AlertProcessor.Parser

  @behaviour Parser

  @doc """
  process_alerts/1 send messages to self for tests to be able
  to verify that process_alerts has properly been called.
  """
  def process_alerts do
    send self(), :processed_alerts
  end
end
