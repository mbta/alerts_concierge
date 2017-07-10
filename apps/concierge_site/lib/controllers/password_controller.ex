defmodule ConciergeSite.PasswordController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.{Model, Repo}
  alias Model.User

  def edit(conn, _params, user, _claims) do
    changeset = User.update_password_changeset(%User{})
    render conn, "edit.html", changeset: changeset, user: user
  end

  def update(conn, %{"user" => user_params}, user, _claims) do
    if User.check_password(user, user_params["current_password"]) do
      changeset = User.update_password_changeset(
        user, Map.take(user_params, ["password", "password_confirmation"])
      )

      case Repo.update(changeset) do
        {:ok, _user} ->
          conn
          |> put_flash(:info, "Your password has been updated.")
          |> redirect(to: my_account_path(conn, :edit))
        {:error, changeset} ->
          render conn,"edit.html", user: user, changeset: changeset
      end
    else
      conn
      |> put_flash(:error, "Current password is incorrect.")
      |> render("edit.html", %{})
    end
  end
end
