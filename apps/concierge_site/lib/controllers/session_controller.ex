defmodule ConciergeSite.SessionController do
  use ConciergeSite.Web, :controller
  alias AlertProcessor.Model.User
  alias ConciergeSite.SignInHelper
  plug(:scrub_params, "user" when action in [:create])

  def new(conn, _params) do
    changeset = User.login_changeset(%User{})
    render(conn, "new.html", login_changeset: changeset)
  end

  def create(conn, %{"user" => login_params}) do
    case User.authenticate(login_params) do
      {:ok, user} ->
        SignInHelper.sign_in(conn, user)

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
    |> redirect(to: session_path(conn, :new))
  end

  @doc """
  Require a user to log in if not authenticated.
  Callback for Guardian.Plug.EnsureAuthenticated.
  """
  def unauthenticated(conn, _params) do
    conn
    |> put_flash(:info, "Please log in")
    |> redirect(to: session_path(conn, :new))
  end

  # this path has changed, so add a redirect incase anyone had bookmarked
  def login_redirect(conn, _params), do: redirect(conn, to: "/login/new")
end
