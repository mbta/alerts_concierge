defmodule ConciergeSite.Plugs.AssignCurrentUser do
  @moduledoc "Puts the signed-in user from Guardian into the conn assigns, for convenience."

  import Plug.Conn
  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    assign(conn, :current_user, Guardian.Plug.current_resource(conn))
  end
end
