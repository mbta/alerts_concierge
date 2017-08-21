defmodule ConciergeSite.SessionController do
  @moduledoc """
  Handles creating and destroying of a session (login/logout)
  """
  use ConciergeSite.Web, :controller
  alias AlertProcessor.Model.User
  import ConciergeSite.SignInHelper, only: [admin_guardian_sign_in: 2]
  plug :scrub_params, "user" when action in [:create]

  def new(conn, _params) do
    changeset = User.login_changeset(%User{})
    render conn, "new.html", login_changeset: changeset
  end

  def create(conn, %{"user" => login_params}) do
    case User.authenticate(login_params) do
      {:ok, user} ->
        if User.is_admin?(user) do
          conn
          |> admin_guardian_sign_in(user)
          |> redirect(to: admin_subscriber_path(conn, :index))
        else
          conn
          |> Guardian.Plug.sign_in(user, :access, perms: %{default: Guardian.Permissions.max})
          |> redirect(to: "/my-subscriptions")
        end
      {:error, :disabled} ->
        conn
        |> put_flash(:error, "Account has been disabled. Please enter your email to re-activate it.")
        |> redirect(to: password_reset_path(conn, :new))
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
    |> redirect(to: "/login/new")
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_flash(:info, "Please log in")
    |> redirect(to: session_path(conn, :new))
  end
end
