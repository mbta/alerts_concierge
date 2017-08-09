defmodule ConciergeSite.Admin.ImpersonateSessionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.{Model.User, Repo}
  alias ConciergeSite.ImpersonateSessionPolicy

  def create(conn, %{"user_id" => user_id}, admin, _claims) do
    user = Repo.get!(User, user_id)

    if ImpersonateSessionPolicy.can?(admin, :impersonate_user, user) do
      conn
      |> Guardian.Plug.sign_out()
      |> Guardian.Plug.sign_in(user, :access, perms: %{default: Guardian.Permissions.max}, imp: admin.id)
      |> put_flash(:info, "You are now logged in on behalf of #{user.email}.")
      |> redirect(to: "/my-subscriptions")
    else
      handle_unauthorized(conn)
    end
  end

  defp handle_unauthorized(conn) do
    conn
    |> put_status(403)
    |> render(ConciergeSite.ErrorView, "403.html")
  end
end
