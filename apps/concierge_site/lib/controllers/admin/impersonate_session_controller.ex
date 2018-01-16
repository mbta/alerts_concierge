defmodule ConciergeSite.Admin.ImpersonateSessionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.{Model.User, Repo}
  alias ConciergeSite.ImpersonateSessionPolicy

  def create(conn, %{"user_id" => user_id}, admin, _claims) do
    user = Repo.get!(User, user_id)

    if ImpersonateSessionPolicy.can?(admin, :impersonate_user, user) do
      User.log_admin_action(:impersonate_subscriber, admin, user)
      conn
      |> Guardian.Plug.sign_out()
      |> Guardian.Plug.sign_in(user, :access, %{perms: %{default: Guardian.Permissions.max}, imp: admin.id})
      |> redirect(to: "/my-subscriptions")
    else
      render_unauthorized(conn)
    end
  end
end
