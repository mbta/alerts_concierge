defmodule MbtaServer.AlertProcessor.Parser do
  @moduledoc """
  Behaviour for parsers. No parameters expected and will
  return a list of :ok or :error atoms based on result of
  alerts parsed and processed otherwise an error message.
  """

  @callback process_alerts() :: [:ok | :error] | String.t
end
