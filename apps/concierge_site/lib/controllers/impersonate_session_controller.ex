defmodule ConciergeSite.ImpersonateSessionController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.{Model.User, Repo}

  def delete(conn, _params, user, claims) do
    conn = Guardian.Plug.sign_out(conn)

    {:ok, %{"imp" => admin_id}} = claims
    admin_user = Repo.get(User, admin_id)

    case admin_user.role do
      "customer_support" ->
        conn
        |> Guardian.Plug.sign_in(admin_user, :token,
          perms: %{default: Guardian.Permissions.max, admin: [:customer_support]})
        |> put_flash(:info, "Successfully signed out of account for user #{user.email}.")
        |> redirect(to: admin_subscriber_path(conn, :index))
      "application_administration" ->
        conn
        |> Guardian.Plug.sign_in(admin_user, :token,
          perms: %{
            default: Guardian.Permissions.max,
            admin: [:customer_support, :application_administration]
          })
        |> put_flash(:info, "Successfully signed out of account for user #{user.email}.")
        |> redirect(to: admin_subscriber_path(conn, :index))
      _ ->
        render_unauthorized(conn)
    end
  end
end
