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
      {:ok, user, "junior_admin"} ->
        conn
        |> Guardian.Plug.sign_in(user, :token,
          perms: %{default: Guardian.Permissions.max, admin: [:junior]})
        |> redirect(to: admin_subscriber_path(conn, :index))
      {:ok, user, "super_admin"} ->
        conn
        |> Guardian.Plug.sign_in(user, :token,
          perms: %{default: Guardian.Permissions.max, admin: [:junior, :super]})
        |> redirect(to: admin_subscriber_path(conn, :index))
      {:unauthorized, user} ->
        changeset = User.login_changeset(user)
        conn
        |> put_flash(:error, "Sorry, you are not authorized to log in.")
        |> render("new.html", login_changeset: changeset)
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Sorry, your login information was incorrect. Please try again.")
        |> render("new.html", login_changeset: changeset)
    end
  end

  def unauthorized(conn, _params) do
    conn
    |> put_flash(:error, "Sorry, you are not authorized to view this page.")
    |> redirect(to: session_path(conn, :new))
  end
end
