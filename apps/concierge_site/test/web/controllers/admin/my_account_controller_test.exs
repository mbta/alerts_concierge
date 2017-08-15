defmodule ConciergeSite.Admin.MyAccountControllerTest do
  use ConciergeSite.ConnCase
  alias AlertProcessor.{Model.Subscription, Model.User, Repo}

  describe "admin user" do
    setup :insert_admin

    test "GET /admin/my-account/edit", %{conn: conn, user: user} do
      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> get(admin_my_account_path(conn, :edit))

      assert html_response(conn, 200) =~ "Account"
    end

    test "PATCH /admin/my-account with valid params", %{conn: conn, user: user} do
      params = %{"user" => %{
        "phone_number" => "5551234567",
        "sms_toggle" => "true"
      }}

      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> patch(admin_my_account_path(conn, :update, params))

      updated_user = Repo.get(User, user.id)

      assert html_response(conn, 302) =~ "admin/my-account/edit"
      assert updated_user.phone_number == "5551234567"
    end

    test "PATCH /admin/my-account with invalid params", %{conn: conn, user: user} do
      params = %{"user" => %{
        "phone_number" => "abc123",
        "sms_toggle" => "true"
      }}

      conn =
        user
        |> guardian_login(conn, :token, @customer_support_token_params)
        |> patch(admin_my_account_path(conn, :update, params))

      assert html_response(conn, 200) =~ "Account could not be updated"
    end

    test "PATCH /admin/my-account with valid params creates mode subscriptions", %{conn: conn} do
      user = insert(:user, role: "application_administration")
      params = %{
        "user" => %{
          "phone_number" => "5551234567",
          "sms_toggle" => "true"
        },
        "mode_subscriptions" => %{
          "bus" => "true",
          "commuter_rail" => "false",
          "ferry" => "true",
          "subway" => "false"
        }
      }

      conn =
        user
        |> guardian_login(conn, :token, @application_administration_token_params)
        |> patch(admin_my_account_path(conn, :update, params))

      updated_user = Repo.get(User, user.id)

      assert Subscription.full_mode_subscription_types_for_user(updated_user) == [:bus, :ferry]
      assert html_response(conn, 302) =~ "admin/my-account/edit"
      assert updated_user.phone_number == "5551234567"
    end
  end

  describe "regular user" do
    setup :insert_user

    test "GET /admin/my-account/edit", %{conn: conn, user: user} do
      conn =
        user
        |> guardian_login(conn)
        |> get(admin_my_account_path(conn, :edit))

      assert html_response(conn, 403) =~ "Forbidden"
    end

    test "PATCH /admin/my-account", %{conn: conn, user: user} do
      params = %{
        "user" => %{
          "phone_number" => "5551234567",
          "sms_toggle" => "true"
        },
        "mode_subscriptions" => %{
          "bus" => "false",
          "commuter_rail" => "false",
          "ferry" => "false",
          "subway" => "false"
        }
      }

      conn =
        user
        |> guardian_login(conn)
        |> patch(admin_my_account_path(conn, :update, params))

      assert html_response(conn, 403) =~ "Forbidden"
    end
  end

  describe "unauthenticated" do
    test "GET /admin/my-account/edit", %{conn: conn} do
      conn = get(conn, admin_my_account_path(conn, :edit))

      assert html_response(conn, 302) =~ "/login/new"
    end

    test "PATCH /admin/my-account", %{conn: conn} do
      params = %{
        "user" => %{
          "phone_number" => "5551234567",
          "sms_toggle" => "true"
        },
        "mode_subscriptions" => %{
          "bus" => "false",
          "commuter_rail" => "false",
          "ferry" => "false",
          "subway" => "false"
        }
      }

      conn = patch(conn, admin_my_account_path(conn, :update, params))

      assert html_response(conn, 302) =~ "/login/new"
    end
  end

  defp insert_admin(_context) do
    {:ok, [user: insert(:user, role: "customer_support")]}
  end

  defp insert_user(_context) do
    {:ok, [user: insert(:user)]}
  end
end
