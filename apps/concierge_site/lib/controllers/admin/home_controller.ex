defmodule ConciergeSite.Admin.HomeController do
  use ConciergeSite.Web, :controller

  def index(conn, _params), do: render(conn, "index.html")
end
