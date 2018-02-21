defmodule ConciergeSite.Admin.MyAccountController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.User
  alias ConciergeSite.UserParams

  def edit(conn, _params, user, _claims) do
    changeset = User.update_account_changeset(user)
    render conn, "edit.html", user: user, changeset: changeset
  end

  def update(conn, %{"user" => user_params}, user, _claims) do
    update_params = UserParams.prepare_for_update_changeset(user_params)

    case User.update_account(user, update_params, user.id) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Account updated.")
        |> redirect(to: admin_my_account_path(conn, :edit))
      {:error, changeset} ->

        conn
        |> put_flash(:error, "Account could not be updated. Please see errors below.")
        |> assign(:user, user)
        |> assign(:changeset, changeset)
        |> render("edit.html")
    end
  end
end
