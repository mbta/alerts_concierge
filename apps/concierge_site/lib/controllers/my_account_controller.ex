defmodule ConciergeSite.MyAccountController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.User
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
        |> put_flash(:error, "Account Preferences could not be updated.")
        |> render("edit.html", user: user, changeset: changeset)
    end
  end
end
