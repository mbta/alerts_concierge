defmodule ConciergeSite.Plugs.TokenRefresh do
  @moduledoc "Refreshes the current user's authentication token if it will expire soon."
  @behaviour Plug

  alias ConciergeSite.Guardian

  @refresh_within_seconds 15 * 60

  def init(opts), do: opts

  def call(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    claims = Guardian.Plug.current_claims(conn)

    if expires_soon?(claims) do
      Guardian.Plug.sign_in(conn, user, Map.delete(claims, "exp"))
    else
      conn
    end
  end

  defp expires_soon?(%{"exp" => exp}) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    exp > now and exp < now + @refresh_within_seconds
  end

  defp expires_soon?(_), do: false
end
