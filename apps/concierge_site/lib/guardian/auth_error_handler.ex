defmodule ConciergeSite.Guardian.AuthErrorHandler do
  @moduledoc false
  use ConciergeSite.Web, :controller

  def auth_error(conn, {:unauthenticated, _reason}, _opts) do
    conn
    |> put_flash(:info, "Please log in.")
    |> redirect(to: session_path(conn, :new))
  end

  def auth_error(conn, {:unauthorized, _reason}, _opts) do
    conn
    |> put_flash(:error, "You are not authorized to view that page.")
    |> redirect(to: "/")
  end
end