defmodule AlertProcessor.RateLimiter do
  @moduledoc "Handle rate limiting of outgoing SMS and Emails"
  alias AlertProcessor.Helpers.ConfigHelper

  @spec check_rate_limit(String.t) :: :ok | :error
  def check_rate_limit(id) do
    scale = ConfigHelper.get_int(:rate_limit_scale)
    limit =  ConfigHelper.get_int(:rate_limit)
    case ExRated.check_rate(id, scale, limit) do
      {:ok, _} -> :ok
      {:error, _} -> {:error, :rate_exceeded}
    end
  end
end
