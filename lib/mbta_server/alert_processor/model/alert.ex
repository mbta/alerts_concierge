defmodule MbtaServer.AlertProcessor.Model.Alert do
  @moduledoc """
  Representation of alert received from MBTA /alerts endpoint
  """
  defstruct [:id, :active_period, :banner, :cause, :created_at,
             :description, :effect, :effect_name, :header, :informed_entity,
             :lifecycle, :severity, :short_header, :timeframe, :updated_at, :url]

  @type t :: %__MODULE__{
    active_period: List.t,
    banner: String.t,
    cause: String.t,
    created_at: DateTime.t,
    description: String.t,
    effect: String.t,
    effect_name: String.t,
    header: String.t,
    id: String.t,
    informed_entity: List.t,
    lifecycle: String.t,
    severity: String.t,
    short_header: String.t,
    timeframe: String.t,
    updated_at: DateTime.t,
    url: String.t
  }
end
