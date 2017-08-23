defmodule ConciergeSite.ImpersonateSessionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.{Model.User, Repo}
  alias ConciergeSite.SignInHelper

  def delete(conn, _params, user, claims) do
    conn = Guardian.Plug.sign_out(conn)

    {:ok, %{"imp" => admin_id}} = claims
    admin_user = Repo.get(User, admin_id)

    if User.is_admin?(admin_user) do
      conn
        |> put_flash(:info, "Successfully signed out of account for user #{user.email}.")
        |> SignInHelper.sign_in(admin_user, redirect: :default)
    else
      render_unauthorized(conn)
    end
  end
end
