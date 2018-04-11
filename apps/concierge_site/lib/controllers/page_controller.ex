defmodule ConciergeSite.PageController do
  use ConciergeSite.Web, :controller

  def index(conn, _params) do
    redirect(conn, to: v2_page_path(conn, :index))
  end
end
