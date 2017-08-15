defmodule ConciergeSite.ImpersonateSessionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.{Model.User, Repo}
  import ConciergeSite.SignInHelper

  def delete(conn, _params, user, claims) do
    conn = Guardian.Plug.sign_out(conn)

    {:ok, %{"imp" => admin_id}} = claims
    admin_user = Repo.get(User, admin_id)

    if admin_user.role in ["customer_support", "application_administration"] do
      conn
        |> admin_guardian_sign_in(admin_user)
        |> put_flash(:info, "Successfully signed out of account for user #{user.email}.")
        |> redirect(to: admin_subscriber_path(conn, :index))
    else
      render_unauthorized(conn)
    end
  end
end
