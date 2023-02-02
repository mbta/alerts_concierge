defmodule ConciergeSite.SessionController do
  use ConciergeSite.Web, :controller
  alias AlertProcessor.Model.User
  alias ConciergeSite.SessionHelper
  plug(:scrub_params, "user" when action in [:create])

  def new(conn, _params) do
    if SessionHelper.keycloak_auth?() do
      redirect(conn, to: "/auth/keycloak")
    else
      changeset = User.login_changeset(%User{})
      render(conn, "new.html", login_changeset: changeset)
    end
  end

  def create(conn, %{"user" => login_params}) do
    case User.authenticate(login_params) do
      {:ok, user} ->
        SessionHelper.sign_in(conn, user)

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Sorry, your login information was incorrect. Please try again.")
        |> render("new.html", login_changeset: changeset)
    end
  end

  def delete(conn, _params) do
    SessionHelper.sign_out(conn)
  end

  # this path has changed, so add a redirect incase anyone had bookmarked
  def login_redirect(conn, _params), do: redirect(conn, to: "/login/new")
end
