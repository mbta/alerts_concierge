defmodule AlertProcessor.Model.DigestDateGroup do
  @moduledoc """
  Representation of DigestGroup Data
  """
  defstruct [:upcoming_weekend, :upcoming_week, :next_weekend, :future]

  @type t :: %__MODULE__{
    upcoming_weekend: {DateTime.t, DateTime.t},
    upcoming_week: {DateTime.t, DateTime.t},
    next_weekend: {DateTime.t, DateTime.t},
    future: {DateTime.t, DateTime.t},
  }
end
