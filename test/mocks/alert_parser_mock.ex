defmodule MbtaServer.AlertProcessor.AlertParserMock do
  def process_alerts do
    send self(), :processed_alerts
  end
end
