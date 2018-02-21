defmodule ConciergeSite.V2.SessionController do
  use ConciergeSite.Web, :controller

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, _params) do
    render conn, "new.html"
  end

  def delete(conn, _params) do
    redirect(conn, to: v2_session_path(conn, :new))
  end
end
