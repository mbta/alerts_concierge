defmodule ConciergeSite.PageController do
  use ConciergeSite.Web, :controller

  def landing(conn, _params) do
    render(
      conn,
      "landing.html",
      wide_layout: true,
      body_class: "landing-page"
    )
  end

  def account_deleted(conn, _params) do
    render(conn, "account_deleted.html")
  end
end
