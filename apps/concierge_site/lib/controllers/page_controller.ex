defmodule ConciergeSite.PageController do
  use ConciergeSite.Web, :controller

  def index(conn, _params) do
    redirect(conn, to: subscription_path(conn, :index))
  end
end
