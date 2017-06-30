defmodule ConciergeSite.Subscriptions.ParamsValidator do
  @moduledoc """
  module for housing common param validation functions for
  subscription creation flow.
  """

  @doc """
  full_error_message_iodata takes an array of error
  messages and returns iodata of a constrcuted full error message.
  """
  @spec full_error_message_iodata([String.t]) :: iodata
  def full_error_message_iodata(errors) do
    [
      "Please correct the following errors to proceed: ",
      Enum.intersperse(errors, ", "),
      "."
    ]
  end
end
