defmodule ConciergeSite.Admin.AdminUserControllerTest do
  use ConciergeSite.ConnCase
  alias AlertProcessor.Model.User

  @application_admin_token_params %{
    default: Guardian.Permissions.max,
    admin: [:application_administration, :customer_support]
  }
  @customer_support_token_params %{
    default: Guardian.Permissions.max,
    admin: [:customer_support]
  }

  describe "application_administration user" do
    setup :insert_application_admin

    test "GET /admin/admin_users", %{conn: conn, user: user} do
      conn =
        user
        |> guardian_login(conn, :token, @application_admin_token_params)
        |> get(admin_admin_user_path(conn, :index))

      assert html_response(conn, 200) =~ "Admins"
    end

    test "GET /admin/admin_users/:id", %{conn: conn, user: user} do
      admin = insert(:user, role: "application_administration")

      conn =
        user
        |> guardian_login(conn, :token, @application_admin_token_params)
        |> get(admin_admin_user_path(conn, :show, admin))

      assert html_response(conn, 200) =~ admin.email
    end

    test "GET /admin/admin_users/new", %{conn: conn, user: user} do
      conn =
        user
        |> guardian_login(conn, :token, @application_admin_token_params)
        |> get(admin_admin_user_path(conn, :new))

      assert html_response(conn, 200) =~ "Create Admin"
    end

    test "PATCH /admin/admin_users/:id/deactivate", %{conn: conn, user: user} do
      admin = insert(:user, role: "application_administration")

      conn =
        user
        |> guardian_login(conn, :token, @application_admin_token_params)
        |> patch(admin_admin_user_path(conn, :deactivate, admin))

      deactivated_user = User.admin_one!(admin.id)

      assert html_response(conn, 200) =~ "Inactive"
      assert deactivated_user.role == "deactivated_admin"
    end

    test "PATCH /admin/admin_users/:id/activate", %{conn: conn, user: user} do
      admin = insert(:user, role: "deactivated_admin")

      conn =
        user
        |> guardian_login(conn, :token, @application_admin_token_params)
        |> patch(admin_admin_user_path(conn, :activate, admin, role: "customer_support"))

      admin = User.admin_one!(admin.id)

      assert html_response(conn, 200) =~ "Active"
      assert admin.role == "customer_support"
    end
  end

  describe "customer_support user" do
    setup :insert_customer_support

    test "GET /admin/admin_users", %{conn: conn, user: user} do
      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> get(admin_admin_user_path(conn, :index))

      assert html_response(conn, 403) =~ "Forbidden"
    end


    test "GET /admin/admin_users/:id", %{conn: conn, user: user} do
      admin = insert(:user, role: "application_administration")

      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> get(admin_admin_user_path(conn, :show, admin))

      assert html_response(conn, 403) =~ "Forbidden"
    end

    test "GET /admin/admin_users/new", %{conn: conn, user: user} do
      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> get(admin_admin_user_path(conn, :new))

      assert html_response(conn, 403) =~ "Forbidden"
    end

    test "PATCH /admin/admin_users/:id/deactivate", %{conn: conn, user: user} do
      admin = insert(:user, role: "application_administration")

      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> patch(admin_admin_user_path(conn, :deactivate, admin))

      admin = User.admin_one!(admin.id)

      assert html_response(conn, 403) =~ "Forbidden"
      assert admin.role == "application_administration"
    end

    test "PATCH /admin/admin_users/:id/activate", %{conn: conn, user: user} do
      admin = insert(:user, role: "deactivated_admin")

      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> patch(admin_admin_user_path(conn, :activate, admin, role: "customer_support"))

      admin = User.admin_one!(admin.id)

      assert html_response(conn, 403) =~ "Forbidden"
      assert admin.role == "deactivated_admin"
    end
  end

  describe "deactivated_admin user" do
    setup :insert_deactivated_admin

    test "GET /admin/admin_users", %{conn: conn, user: user} do
      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> get(admin_admin_user_path(conn, :index))

      assert html_response(conn, 403) =~ "Forbidden"
    end

    test "GET /admin/admin_users/:id", %{conn: conn, user: user} do
      admin = insert(:user, role: "application_administration")

      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> get(admin_admin_user_path(conn, :show, admin))

      assert html_response(conn, 403) =~ "Forbidden"
    end

    test "PATCH /admin/admin_users/:id/deactivate", %{conn: conn, user: user} do
      admin = insert(:user, role: "application_administration")

      conn =
        user
        |> guardian_login(conn, :token, @application_admin_token_params)
        |> patch(admin_admin_user_path(conn, :deactivate, admin))

      admin = User.admin_one!(admin.id)

      assert html_response(conn, 403) =~ "Forbidden"
      assert admin.role == "application_administration"
    end

    test "PATCH /admin/admin_users/:id/activate", %{conn: conn, user: user} do
      admin = insert(:user, role: "deactivated_admin")

      conn =
        user
        |> guardian_login(conn, :token, @application_admin_token_params)
        |> patch(admin_admin_user_path(conn, :activate, admin, role: "customer_support"))

      admin = User.admin_one!(admin.id)

      assert html_response(conn, 403) =~ "Forbidden"
      assert admin.role == "deactivated_admin"
    end
  end

  describe "regular user" do
    setup :insert_user

    test "GET /admin/admin_users", %{conn: conn, user: user} do
      conn =
        user
        |> guardian_login(conn)
        |> get(admin_admin_user_path(conn, :index))

      assert html_response(conn, 403) =~ "Forbidden"
    end

    test "GET /admin/admin_users/:id", %{conn: conn, user: user} do
      admin = insert(:user, role: "application_administration")

      conn =
        user
        |> guardian_login(conn)
        |> get(admin_admin_user_path(conn, :show, admin))

      assert html_response(conn, 403) =~ "Forbidden"
    end

    test "GET /admin/admin_users/new", %{conn: conn, user: user} do
      conn =
        user
        |> guardian_login(conn)
        |> get(admin_admin_user_path(conn, :new))

      assert html_response(conn, 403) =~ "Forbidden"
    end

    test "PATCH /admin/admin_users/:id/deactivate", %{conn: conn, user: user} do
      admin = insert(:user, role: "application_administration")

      conn =
        user
        |> guardian_login(conn)
        |> patch(admin_admin_user_path(conn, :deactivate, admin))

      admin = User.admin_one!(admin.id)

      assert html_response(conn, 403) =~ "Forbidden"
      assert admin.role == "application_administration"
    end

    test "PATCH /admin/admin_users/:id/activate", %{conn: conn, user: user} do
      admin = insert(:user, role: "deactivated_admin")

      conn =
        user
        |> guardian_login(conn)
        |> patch(admin_admin_user_path(conn, :activate, admin, role: "customer_support"))

      admin = User.admin_one!(admin.id)

      assert html_response(conn, 403) =~ "Forbidden"
      assert admin.role == "deactivated_admin"
    end
  end

  describe "unauthenticated" do
    test "GET /admin/admin_users", %{conn: conn} do
      conn = get(conn, admin_admin_user_path(conn, :index))

      assert html_response(conn, 302) =~ "/login/new"
    end

    test "GET /admin/admin_users/:id", %{conn: conn} do
      conn = get(conn, admin_admin_user_path(conn, :show, 1))

      assert html_response(conn, 302) =~ "/login/new"
    end

    test "GET /admin/admin_users/new", %{conn: conn} do
      conn = get(conn, admin_admin_user_path(conn, :new))

      assert html_response(conn, 302) =~ "/login/new"
    end

    test "PATCH /admin/admin_users/:id/deactivate", %{conn: conn} do
      admin = insert(:user, role: "application_administration")

      conn = patch(conn, admin_admin_user_path(conn, :deactivate, admin))

      admin = User.admin_one!(admin.id)

      assert html_response(conn, 302) =~ "/login/new"
      assert admin.role == "application_administration"
    end

    test "PATCH /admin/admin_users/:id/activate", %{conn: conn} do
      admin = insert(:user, role: "deactivated_admin")

      conn = patch(conn, admin_admin_user_path(conn, :activate, admin, role: "customer_support"))

      admin = User.admin_one!(admin.id)

      assert html_response(conn, 302) =~ "/login/new"
      assert admin.role == "deactivated_admin"
    end
  end

  describe "valid params" do
    test "only super admins can create other admin users", %{conn: conn} do
      conn =
        :user
        |> insert(role: "application_administration")
        |> guardian_login(conn, :token, %{
            default: Guardian.Permissions.max,
            admin: [:application_administration, :customer_support]
          })

      admin_user_params =
              %{"user" => %{
                "email" => "admin@mbta.com",
                "password" => "password1",
                "password_confirmation" => "password1",
                "role" => "customer_support"
              }}

      conn = post(conn, "/admin/admin_users/", admin_user_params)
      assert html_response(conn, 302) =~ "/admin/admin_users"
    end
  end

  describe "invalid params" do
    test "admin user cannot create other admin users without valid params", %{conn: conn} do
      conn =
        :user
        |> insert(role: "application_administration")
        |> guardian_login(conn, :token, %{
            default: Guardian.Permissions.max,
            admin: [:application_administration, :customer_support]
         })

      invalid_admin_user_params =
              %{"user" => %{
                "email" => "admin@mbta.com",
                "password" => "password1",
                "password_confirmation" => "password1",
                "role" => nil
              }}

      conn = post(conn, "/admin/admin_users/", invalid_admin_user_params)
      response = html_response(conn, 200)

      assert response =~ "can&#39;t be blank"
    end
  end

  defp insert_application_admin(_context) do
    {:ok, [user: insert(:user, role: "application_administration")]}
  end

  defp insert_customer_support(_context) do
    {:ok, [user: insert(:user, role: "customer_support")]}
  end

  defp insert_deactivated_admin(_context) do
    {:ok, [user: insert(:user, role: "deactivated_admin")]}
  end

  defp insert_user(_context) do
    {:ok, [user: insert(:user, role: "user")]}
  end
end
