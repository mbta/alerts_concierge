defmodule ConciergeSite.PasswordController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.User

  plug :reauthorize_user when action in [:update]

  def edit(conn, _params, user, _claims) do
    changeset = User.update_password_changeset(user)
    render conn, "edit.html", changeset: changeset, user: user
  end

  def update(conn, %{"user" => user_params}, user, {:ok, claims}) do
    case User.update_password(user, user_params, Map.get(claims, "imp", user.id)) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Your password has been updated.")
        |> redirect(to: my_account_path(conn, :edit))
      {:error, changeset} ->
        render conn, "edit.html", user: user, changeset: changeset
    end
  end

  defp reauthorize_user(conn, _params) do
    user = conn.private.guardian_default_resource
    password = conn.params["user"]["current_password"]

    if User.check_password(user, password) do
      conn
    else
      changeset = User.update_password_changeset(user)

      conn
      |> put_flash(:error, "Current password is incorrect.")
      |> render("edit.html", changeset: changeset, user: user)
      |> halt()
    end
  end
end
