defmodule ConciergeSite.V2.LegController do
  use ConciergeSite.Web, :controller

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, _params) do
    render conn, "new.html"
  end
end
