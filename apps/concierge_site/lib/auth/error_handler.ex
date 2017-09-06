defmodule ConciergeSite.Auth.ErrorHandler do
  @moduledoc false
  use ConciergeSite.Web, :controller

  def unauthorized(conn, _params) do
    conn
    |> put_flash(:error, "Unauthorized")
    |> redirect(to: "/login/new")
  end
end
