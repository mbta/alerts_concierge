defmodule ConciergeSite.Plugs.RateLimit do
  @moduledoc "Limits IPs or users to a reasonable number of requests per unit of time."

  import Plug.Conn
  @behaviour Plug

  @limit_anonymous 5
  @limit_signed_in 30
  @one_minute 60_000

  @doc """
  Initialize the plug. If the option `enable?: false` is given, no actual rate limiting will be
  performed except for requests with a `rate_limit?: true` assign in the conn (e.g. in tests).
  """
  @impl Plug
  def init(opts), do: %{enable?: Keyword.get(opts, :enable?, true)}

  @impl Plug
  def call(%{assigns: %{rate_limit?: true}} = conn, %{enable?: false} = opts),
    do: call(conn, Map.put(opts, :enable?, true))

  def call(conn, %{enable?: false}), do: conn
  def call(%{method: "GET"} = conn, _opts), do: conn

  def call(%{assigns: %{current_user: %{id: id}}} = conn, _opts),
    do: limit(conn, id, @limit_signed_in)

  def call(%{remote_ip: ip} = conn, _opts), do: limit(conn, ip_string(ip), @limit_anonymous)

  defp limit(conn, identifier, count) do
    case Hammer.check_rate(identifier, @one_minute, count) do
      {:allow, _count} -> conn
      {:deny, _limit} -> conn |> send_resp(429, "Too many requests!") |> halt()
    end
  end

  defp ip_string(address) do
    case :inet.ntoa(address) do
      {:error, _} -> "invalid"
      result -> to_string(result)
    end
  end
end
