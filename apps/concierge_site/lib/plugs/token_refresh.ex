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
         {:ok, claims} <- Guardian.decode_and_verify(token) do
           case Guardian.refresh!(token, claims, %{ttl: {60, :minutes}}) do
             {:ok, new_token, new_claims} ->
               new_claims = Guardian.Claims.permissions(new_claims, admin: [:customer_support, :application_administration], default: Guardian.Permissions.max)
               key = Map.get(new_claims, :key, :default)
               current_user = current_resource(conn)
              conn
              |> configure_session(renew: true)
              |> put_session(Guardian.Keys.base_key(key), new_token)
              |> set_current_resource(current_user, key)
              |> set_claims({:ok, new_claims}, key)
              |> set_current_token(new_token, key)
             {:error, _} ->
               conn
           end
    else
      _ -> conn
    end
  end
end
