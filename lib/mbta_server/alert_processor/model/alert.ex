defmodule MbtaServer.AlertProcessor.Model.Alert do
  @moduledoc """
  Representation of alert received from MBTA /alerts endpoint
  """
  defstruct [:id, :header]

  @type t :: %__MODULE__{
    header: String.t,
    id: String.t
  }
end
