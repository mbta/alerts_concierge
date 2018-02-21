defmodule ConciergeSite.V2.TripController do
  use ConciergeSite.Web, :controller

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, _params) do
    render conn, "new.html"
  end

  def edit(conn, _params) do
    render conn, "edit.html"
  end

  def update(conn, _params) do
    render conn, "edit.html"
  end

  def new_times(conn, _params) do
    render conn, "new_times.html"
  end

  def create_times(conn, _params) do
    render conn, "new_times.html"
  end

  def accessibility(conn, _params) do
    render conn, "accessibility.html"
  end
end
