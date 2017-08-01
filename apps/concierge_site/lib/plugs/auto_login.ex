defmodule ConciergeSite.Plugs.AutoLogin do
  @moduledoc """
  Plug to check query params for a valid token
  and if found, puts into session in expected location
  to authenticate user.
  """
  import Plug.Conn

  def init(opts \\ %{}), do: Enum.into(opts, %{})

  def call(conn, _) do
    case conn.query_params["token"] do
      nil -> conn
      token ->
        with {:ok, claims} <- Guardian.decode_and_verify(token),
          key <- Map.get(claims, :key, :default) do
            put_session(conn, Guardian.Keys.base_key(key), token)
        else
          _ -> conn
        end
    end
  end
end
