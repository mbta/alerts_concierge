defmodule ConciergeSite.AuthorizationHelper do
  @moduledoc """
  Functions for handling common authorization responses
  """

  import Plug.Conn
  import Phoenix.Controller

  def render_unauthorized(conn) do
    conn
    |> put_status(403)
    |> put_view(ConciergeSite.ErrorView)
    |> render("403.html", %{})
  end
end
