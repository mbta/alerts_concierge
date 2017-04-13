defmodule MbtaServer.AlertProcessor.Model.Alert do
  @moduledoc """
  Representation of alert received from MBTA /alerts endpoint
  """
  defstruct [:id, :header, :informed_entities]

  @type t :: %__MODULE__{
    header: String.t,
    id: String.t,
    informed_entities: [map]
  }
end
