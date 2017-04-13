defmodule MbtaServer.AlertProcessor.Model.Subscription do
  @moduledoc """
  Set of criteria on which a user wants to be sent alerts.
  """
  alias MbtaServer.AlertProcessor.Model.InformedEntity

  defstruct [:alert_types, :end_time, :informed_entities, :priority, :start_time, :travel_days, :user_id]

  @type t :: %__MODULE__{
    alert_types: [String.t],
    end_time: DateTime.t,
    informed_entities: [InformedEntity.t],
    priority: String.t,
    start_time: DateTime.t,
    travel_days: [String.t],
    user_id: String.t
  }
end
