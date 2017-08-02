defmodule ConciergeSite.Plugs.TokenLogin do
  @moduledoc """
  Plug to check query params for a valid token
  and if found, puts into session in expected location
  to authenticate user.
  """
  import Plug.Conn
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    with {:ok, token} <- Map.fetch(conn.params, "token"),
         {:ok, claims} <- Guardian.decode_and_verify(token) do
      key =
        claims
        |> Map.get(:key, :default)
        |> Guardian.Keys.base_key()
      put_session(conn, key, token)
    else
      _ -> conn
    end
  end
end
