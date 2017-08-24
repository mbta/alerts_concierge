defmodule ConciergeSite.Plugs.TokenRefresh do
  @moduledoc """
  Plug to check query params for a valid token
  and if found, puts into session in expected location
  to authenticate user.
  """
  import Plug.Conn
  import Guardian.Plug
  import AlertProcessor.Model.User, only: [claims_with_permission: 3]
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    with token <- get_session(conn, "guardian_default"),
         {:ok, claims} <- Guardian.decode_and_verify(token),
         {:ok, new_token, new_claims} <- Guardian.refresh!(token, claims, %{ttl: {60, :minutes}}) do
      current_user = current_resource(conn)
      new_claims = claims_with_permission(claims, new_claims, current_user)
      key = Map.get(new_claims, :key, :default)

      conn
      |> configure_session(renew: true)
      |> put_session(Guardian.Keys.base_key(key), new_token)
      |> set_current_resource(current_user, key)
      |> set_claims({:ok, new_claims}, key)
      |> set_current_token(new_token, key)
    else
      _ -> conn
    end
  end
end
