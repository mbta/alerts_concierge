defmodule ConciergeSite.Admin.AdminsController do
  use ConciergeSite.Web, :controller

  alias AlertProcessor.Repo
  alias AlertProcessor.Model.User

  def index(conn, _params) do
    render(conn, "index.html", admins: User.admins())
  end

  def create(%{assigns: %{current_user: current_user}} = conn, %{"email" => email}) do
    with user when not is_nil(user) <- User.for_email(email),
         false <- User.admin?(user),
         {:ok, _} <- User.make_admin(user, current_user) do
      redirect_to_index(conn, :info, "Granted admin access to: #{email}")
    else
      nil ->
        redirect_to_index(conn, :error, "User does not exist: #{email}")

      true ->
        redirect_to_index(conn, :error, "User already has admin access: #{email}")

      {:error, error} ->
        redirect_to_index(conn, :error, "Could not grant admin access: #{inspect(error)}")
    end
  end

  def delete(%{assigns: %{current_user: current_user}} = conn, %{"id" => id}) do
    case User |> Repo.get!(id) |> User.make_not_admin(current_user) do
      {:ok, %{email: email}} ->
        redirect_to_index(conn, :info, "Removed admin access from: #{email}")

      {:error, error} ->
        redirect_to_index(conn, :error, "Could not remove admin access: #{inspect(error)}")
    end
  end

  defp redirect_to_index(conn, flash_type, flash_content) do
    conn
    |> put_flash(flash_type, flash_content)
    |> redirect(to: admin_admins_path(conn, :index))
  end
end
