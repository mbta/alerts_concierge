defmodule MbtaServer.AlertProcessor.Model.Alert do
  @moduledoc """
  Representation of alert received from MBTA /alerts endpoint
  """
  defstruct [:effect_name, :id, :header, :informed_entities, :severity]

  @type t :: %__MODULE__{
    effect_name: String.t,
    header: String.t,
    id: String.t,
    informed_entities: [map],
    severity: String.t
  }

  @severity_values %{
    "Minor" => 1,
    "Moderate" => 2,
    "Severe" => 3
  }

  def severity_value(%__MODULE__{severity: severity}) do
    @severity_values[severity]
  end
end
