defmodule ConciergeSite.AuthorizationHelper do
  @moduledoc """
  Functions for handling common authorization responses
  """

  import Plug.Conn, only: [put_status: 2]
  import Phoenix.Controller, only: [render: 4]

  def render_unauthorized(conn) do
    conn
    |> put_status(403)
    |> render(ConciergeSite.ErrorView, "403.html", %{})
  end
end
