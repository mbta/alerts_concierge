defmodule AlertProcessor.DigestBuilder do
  @moduledoc """
  Generates digests for all users/alerts in the system
  """

  @doc """
  1. Fetch all digests
  2. For each user, filter the digests they should receive
  3. Disseminate
  """
  @spec send_digests() :: :ok
  def send_digests do
    # TODO:
    # alerts = AlertCache.get_alerts()
    # filter for each user by informed entity
    # build digest for each user for all relevant alerts
    :ok
  end
end
