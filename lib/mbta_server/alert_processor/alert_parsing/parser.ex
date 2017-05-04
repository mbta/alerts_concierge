defmodule MbtaServer.AlertProcessor.Parser do
  @moduledoc """
  Behaviour for parsers. No parameters expected and will
  return a list of :ok and a list of notifications based
  on result of alerts parsed and processed.
  """
  alias MbtaServer.AlertProcessor.Model.Notification

  @callback process_alerts() :: [{:ok, [Notification.t]}]
end
