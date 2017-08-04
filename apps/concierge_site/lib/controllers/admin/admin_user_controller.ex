defmodule ConciergeSite.Admin.AdminUserController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.{Model.User}
  alias ConciergeSite.AdminUserPolicy

  plug :scrub_params, "user" when action in [:create]
  @admin_roles ["Customer Support": "customer_support",
                "Application Administration": "application_administration"]

  def index(conn, _params, user, _claims) do
    if AdminUserPolicy.can?(user, :list_admin_users) do
      admin_users = User.all_admin_users()
      render conn, "index.html", admin_users: admin_users
    else
      handle_unauthorized(conn)
    end
  end

  def new(conn, _params, user, _claims) do
    if AdminUserPolicy.can?(user, :create_admin_users) do
      account_changeset = User.create_account_changeset(%User{})
      render conn, "new.html", account_changeset: account_changeset,
                    admin_roles: @admin_roles, errors: []
    else
      handle_unauthorized(conn)
    end
  end

  def create(conn, %{"user" => admin_user_params}, user, _claims) do
    if AdminUserPolicy.can?(user, :create_admin_users) do
      case User.create_admin_account(admin_user_params) do
        {:ok, _} ->
          conn
          |> redirect(to: "/admin/admin_users")
        {:error, changeset} ->
          render conn, "new.html", account_changeset: changeset,
                        admin_roles: @admin_roles, errors: errors(changeset)
      end
    else
        handle_unauthorized(conn)
    end
  end

  defp errors(changeset) do
    Enum.map(changeset.errors, fn({field, _}) ->
      field
    end)
  end

  defp handle_unauthorized(conn) do
    conn
    |> put_status(403)
    |> render(ConciergeSite.ErrorView, "403.html")
  end
end
