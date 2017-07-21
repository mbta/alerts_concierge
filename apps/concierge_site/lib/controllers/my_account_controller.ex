defmodule ConciergeSite.MyAccountController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.{Model, Repo}
  alias Model.User
  alias AlertProcessor.Repo
  alias ConciergeSite.UserParams

  def edit(conn, _params, user, _claims) do
    changeset = User.update_account_changeset(user)
    render conn, "edit.html", changeset: changeset, user: user
  end

  def update(conn, %{"user" => user_params}, user, _claims) do
    params = UserParams.prepare_for_update_changeset(user_params)
    changeset = User.update_account_changeset(user, params)

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Account Preferences updated.")
        |> redirect(to: my_account_path(conn, :edit))
      {:error, changeset} ->
        conn
        |> put_flash(:error, "Account Preferences could not be updated. Please see errors below.")
        |> render("edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, _params, user, _claims) do
    changeset = User.disable_account_changeset(user)

    case Repo.update(changeset) do
      {:ok, _} ->
        conn
        |> Guardian.Plug.sign_out()
        |> put_flash(:info, "Your account has been deleted.")
        |> redirect(to: session_path(conn, :new))
      {:error, _} ->
        conn
        |> put_flash(:error, "Your account could not be deleted, please try again.")
        |> render("confirm_delete.html")
    end
  end

  def confirm_delete(conn, _params, _user, _claims) do
    render conn, "confirm_delete.html"
  end
end
