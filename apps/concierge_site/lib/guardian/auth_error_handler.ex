defmodule ConciergeSite.Guardian.AuthErrorHandler do
  @moduledoc false
  use ConciergeSite.Web, :controller

  def auth_error(conn, {:unauthorized, _reason}, _opts) do
    conn
    |> put_flash(:error, "You are not authorized to view that page.")
    |> redirect(to: trip_path(conn, :index))
  end

  def auth_error(conn, {_failure, _reason}, _opts) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Please log in.")
    |> redirect(to: session_path(conn, :new))
  end
end
