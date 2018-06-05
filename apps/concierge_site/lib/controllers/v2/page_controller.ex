defmodule ConciergeSite.V2.PageController do
  use ConciergeSite.Web, :controller

  def account_deleted(conn, _params) do
    render conn, "account_deleted.html"
  end
end
