defmodule ConciergeSite.PageController do
  use ConciergeSite.Web, :controller

  def index(conn, _params) do
    redirect(conn, to: subscription_path(conn, :index))
  end

  def account_disabled(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> render("account_disabled.html")
  end
end
