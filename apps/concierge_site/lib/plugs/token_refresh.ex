defmodule ConciergeSite.Plugs.TokenRefresh do
  @moduledoc """
  Plug to check query params for a valid token
  and if found, puts into session in expected location
  to authenticate user.
  """
  import Plug.Conn
  import Guardian.Plug
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    with token <- get_session(conn, "guardian_default"),
         {:ok, claims} <- Guardian.decode_and_verify(token),
         true <- token_expires_within_fifteen_minutes?(claims) do

      current_user = current_resource(conn)
      sign_in(conn, current_user, :access, %{perms: map_permissions(claims["pem"])})
    else
      _ -> conn
    end
  end

  defp map_permissions(%{"admin" => admin, "default" => default}), do: %{admin: admin, default: default}
  defp map_permissions(%{"default" => default}), do: %{default: default}

  defp token_expires_within_fifteen_minutes?(%{"exp" => exp}) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    fifteen_minutes_from_now = (15 * 60) + now
    exp > now and exp < fifteen_minutes_from_now
  end
end
