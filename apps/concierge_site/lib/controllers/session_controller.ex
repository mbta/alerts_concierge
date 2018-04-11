defmodule ConciergeSite.SessionController do
  @moduledoc """
  Handles creating and destroying of a session (login/logout)
  """
  use ConciergeSite.Web, :controller
  plug :scrub_params, "user" when action in [:create]

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> Guardian.Plug.sign_out()
    |> redirect(to: "/v2/login/new")
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_flash(:info, "Please log in")
    |> redirect(to: v2_session_path(conn, :new))
  end
end
