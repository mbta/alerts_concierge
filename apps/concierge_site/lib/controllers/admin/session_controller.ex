defmodule ConciergeSite.Admin.SessionController do
  use ConciergeSite.Web, :controller
  alias AlertProcessor.Model.User
  plug :scrub_params, "user" when action in [:create]

  def new(conn, _params) do
    changeset = User.login_changeset(%User{})
    render conn, "new.html", login_changeset: changeset
  end

  def create(conn, %{"user" => login_params}) do
    case User.authenticate_admin(login_params) do
      {:ok, user, "customer_support"} ->
        conn
        |> Guardian.Plug.sign_in(user, :token,
          perms: %{default: Guardian.Permissions.max, admin: [:customer_support]})
        |> redirect(to: admin_subscriber_path(conn, :index))
      {:ok, user, "application_administration"} ->
        conn
        |> Guardian.Plug.sign_in(user, :token,
          perms: %{
            default: Guardian.Permissions.max,
            admin: [:customer_support, :application_administration]
          })
        |> redirect(to: admin_subscriber_path(conn, :index))
      :unauthorized ->
        conn
        |> put_status(403)
        |> render(ConciergeSite.ErrorView, "403.html")
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Sorry, your login information was incorrect. Please try again.")
        |> render("new.html", login_changeset: changeset)
    end
  end

  def unauthorized(conn, _params) do
    conn
    |> put_status(403)
    |> render(ConciergeSite.ErrorView, "403.html")
  end
end
