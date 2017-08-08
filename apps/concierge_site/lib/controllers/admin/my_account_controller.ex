defmodule ConciergeSite.Admin.MyAccountController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller

  def edit(conn, _params, user, _claims) do
    render conn, "edit.html", user: user
  end
end
