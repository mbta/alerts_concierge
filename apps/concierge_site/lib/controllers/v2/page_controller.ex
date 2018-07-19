defmodule ConciergeSite.V2.PageController do
  use ConciergeSite.Web, :controller

  def landing(conn, _params) do
    render conn, "landing.html", wide_layout: true, body_class: "landing-page", header_note: "The <a href='https://public.govdelivery.com/accounts/MABTA/subscriber/new' target='_blank'>old T-alerts system</a> will be turned off in late August 2018. Sign up for a beta account to continue receiving alerts."
  end

  def account_deleted(conn, _params) do
    render conn, "account_deleted.html"
  end
end
