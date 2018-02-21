defmodule ConciergeSite.V2.AccountController do
  use ConciergeSite.Web, :controller

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, _params) do
    render conn, "new.html"
  end

  def options(conn, _params) do
    render conn, "options.html"
  end
end
