defmodule AlertProcessor.Model.DigestDateGroup do
  @moduledoc """
  Representation of DigestGroup Data
  """
  defstruct [:upcoming_weekend, :upcoming_week, :next_weekend, :future]

  @type t :: %__MODULE__{
    upcoming_weekend: %{
      timeframe: {DateTime.t, DateTime.t},
      alert_ids: [String.t]
    },
    upcoming_week: %{
      timeframe: {DateTime.t, DateTime.t},
      alert_ids: [String.t]
    },
    next_weekend: %{
      timeframe: {DateTime.t, DateTime.t},
      alert_ids: [String.t]
    },
    future: %{
      timeframe: {DateTime.t, DateTime.t},
      alert_ids: [String.t]
    }
  }
end
