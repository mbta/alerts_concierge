defmodule ConciergeSite.Auth.ErrorHandler do
  @moduledoc false
  use ConciergeSite.Web, :controller

  def unauthorized(conn, _params) do
    conn
    |> put_flash(:error, "Please log in to gain access to the rest of the site")
    |> redirect(to: "/login/new")
  end
end
