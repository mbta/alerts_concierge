defmodule ConciergeSite.Admin.SessionController do
  use ConciergeSite.Web, :controller
  alias AlertProcessor.Model.User
  import ConciergeSite.SignInHelper, only: [admin_guardian_sign_in: 2]

  plug :scrub_params, "user" when action in [:create]

  def new(conn, _params) do
    changeset = User.login_changeset(%User{})
    render conn, "new.html", login_changeset: changeset
  end

  def create(conn, %{"user" => login_params}) do
    case User.authenticate_admin(login_params) do
      {:ok, user} ->
        conn
        |> admin_guardian_sign_in(user)
        |> redirect(to: admin_subscriber_path(conn, :index))
      :deactivated ->
        changeset = User.login_changeset(%User{})
        conn
        |> put_flash(:error, "Sorry, your account has been deactivated. Please contact an administrator.")
        |> render("new.html", login_changeset: changeset)
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

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> Guardian.Plug.sign_out()
    |> redirect(to: admin_session_path(conn, :new))
  end

  def unauthorized(conn, _params), do: render_unauthorized(conn)
end
