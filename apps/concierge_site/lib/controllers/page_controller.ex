defmodule ConciergeSite.PageController do
  use ConciergeSite.Web, :controller

  def index(conn, _params) do
    redirect(conn, to: subscription_path(conn, :index))
  end

  def account_suspended(conn, _params) do
    render(conn, "account_suspended.html")
  end
end
