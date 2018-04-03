defmodule ConciergeSite.V2.PageController do
  use ConciergeSite.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def trip_type(conn, _params) do
    render conn, "trip_type.html"
  end
end
