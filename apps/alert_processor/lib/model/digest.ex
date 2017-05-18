defmodule AlertProcessor.Model.Digest do
  @moduledoc """
  Representation of Digest data
  """
  alias AlertProcessor.{Model.User, Model.Alert}
  defstruct [:user, :alerts, :serialized_alerts]

  @type t :: %__MODULE__{
    user: User.t,
    alerts: [Alert.t],
    serialized_alerts: [String.t]
  }
end
