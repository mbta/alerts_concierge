defmodule ConciergeSite.Plugs.SaveCurrentUser do
  @moduledoc """
  Plug to check whether an user has signed in.
  """

  import Plug.Conn
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    assign(conn, :current_user, Guardian.Plug.current_resource(conn))
  end
end
