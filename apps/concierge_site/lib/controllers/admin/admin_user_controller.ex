defmodule ConciergeSite.Admin.AdminUserController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.Model.User
  alias ConciergeSite.AdminUserPolicy

  plug :scrub_params, "user" when action in [:create]
  @admin_roles ["Customer Support": "customer_support",
                "Application Administration": "application_administration"]

  def index(conn, _params, user, _claims) do
    if AdminUserPolicy.can?(user, :list_admin_users) do
      admin_users = User.all_admin_users()
      render conn, "index.html", admin_users: admin_users
    else
      render_unauthorized(conn)
    end
  end

  def new(conn, _params, user, _claims) do
    if AdminUserPolicy.can?(user, :create_admin_users) do
      account_changeset = User.create_account_changeset(%User{})
      render conn, "new.html", account_changeset: account_changeset,
                    admin_roles: @admin_roles, errors: []
    else
      render_unauthorized(conn)
    end
  end

  def show(conn, %{"id" => id}, user, _claims) do
    if AdminUserPolicy.can?(user, :show_admin_user) do
      admin_user = User.admin_one!(id)
      log_details = PaperTrail.get_versions(admin_user)
      render conn, "show.html", admin_user: admin_user, log_details: log_details
    else
      render_unauthorized(conn)
    end
  end

  def confirm_role_change(conn, %{"id" => id}, user, _claims) do
    if AdminUserPolicy.can?(user, :update_admin_roles) do
      admin_user = User.admin_one!(id)
      render conn, "confirm_role_change.html", admin_user: admin_user, admin_roles: @admin_roles
    else
      render_unauthorized(conn)
    end
  end

  def deactivate(conn, %{"id" => id}, user, _claims) do
    if AdminUserPolicy.can?(user, :deactivate_admin_user) do
      admin_user = User.admin_one!(id)
      log_details = PaperTrail.get_versions(admin_user)

      case User.deactivate_admin(admin_user) do
        {:ok, updated_user} ->
          conn
          |> put_flash(:error, "Admin User deactivated.")
          |> render("show.html", admin_user: updated_user, log_details: [])
        {:error, _} ->
          conn
          |> put_flash(:error, "Admin User could not be deactivated.")
          |> render("show.html", admin_user: admin_user, log_details: log_details)
      end
    else
      render_unauthorized(conn)
    end
  end

  def activate(conn, %{"id" => id} = params, user, _claims) do
    if AdminUserPolicy.can?(user, :activate_admin_user) do
      admin_user = User.admin_one!(id)
      log_details = PaperTrail.get_versions(admin_user)

      case User.activate_admin(admin_user, params["user"]) do
        {:ok, updated_user} ->
          conn
          |> put_flash(:info, "Admin User activated with #{updated_user.role} role.")
          |> render("show.html", admin_user: updated_user, log_details: log_details)
        {:error, _} ->
          conn
          |> put_flash(:error, "Admin User could not be activated.")
          |> render("show.html", admin_user: admin_user, log_details: [])
      end
    else
      render_unauthorized(conn)
    end
  end

  def confirm_activate(conn, %{"id" => id}, user, _claims) do
    if AdminUserPolicy.can?(user, :activate_admin_user) do
      admin_user = User.admin_one!(id)
      render conn, "confirm_activate.html", admin_user: admin_user,
                    admin_roles: @admin_roles
    else
      render_unauthorized(conn)
    end
  end

  def confirm_deactivate(conn, %{"id" => id}, user, _claims) do
    if AdminUserPolicy.can?(user, :deactivate_admin_user) do
      admin_user = User.admin_one!(id)
      render conn, "confirm_deactivate.html", admin_user: admin_user
    else
      render_unauthorized(conn)
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
      render_unauthorized(conn)
    end
  end

  def update(conn, %{"id" => id, "user" => admin_user_params}, user, _claims) do
    if AdminUserPolicy.can?(user, :update_admin_roles) do
      admin_user = User.admin_one!(id)
      log_details = PaperTrail.get_versions(admin_user)

      case User.change_admin_role_changeset(admin_user, admin_user_params["role"]) do
        {:ok, updated_user} ->
          conn
          |> put_flash(:error, "Admin User's Role has been changed.")
          |> render("show.html", admin_user: updated_user, log_details: log_details)
        {:error, _} ->
          conn
          |> put_flash(:error, "Admin User's Role cannot be changed.")
          |> render("show.html", admin_user: admin_user, log_details: log_details)
      end
    else
      render_unauthorized(conn)
    end
  end

  defp errors(changeset) do
    Enum.map(changeset.errors, fn({field, _}) ->
      field
    end)
  end
end
