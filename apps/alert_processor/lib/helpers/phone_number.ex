defmodule AlertProcessor.Helpers.PhoneNumber do
  @moduledoc """
  Helper functions for parsing and formatting phone numbers
  """

  @spec strip_us_country_code(String.t() | nil) :: String.t() | nil
  def strip_us_country_code("+1" <> phone_number), do: phone_number
  def strip_us_country_code(phone_number), do: phone_number
end
