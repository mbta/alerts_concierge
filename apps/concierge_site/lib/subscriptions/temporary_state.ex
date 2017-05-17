defmodule ConciergeSite.Subscriptions.TemporaryState do
  @moduledoc """
  Module for encoding a map representing current state of
  a subscription before persisting to the database
  and validating the token generated on the next request.
  """
  alias AlertProcessor.Helpers.ConfigHelper

  @spec valid?(String.t, map) :: boolean
  def valid?(token, data) do
    do_encode(data) == token
  end

  @spec encode(map) :: String.t
  def encode(data) do
    do_encode(data)
  end

  defp do_encode(data) do
    to_string(:crypto.hmac(:sha256, secret_key(), Poison.encode!(data)))
  end

  defp secret_key do
    ConfigHelper.get_string(:temp_state_key, :concierge_site)
  end
end
