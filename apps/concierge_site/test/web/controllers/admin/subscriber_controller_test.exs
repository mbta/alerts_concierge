defmodule ConciergeSite.Admin.SubscriberControllerTest do
  use ConciergeSite.ConnCase

  describe "admin user" do
    setup :create_and_login_user

    setup do
      subscriber1 = insert(:user, email: "this@email.com", phone_number: "5551231234")
      subscriber2 = insert(:user, email: "that@email.com", phone_number: "5550202020", encrypted_password: "")
      {:ok, subscriber1: subscriber1, subscriber2: subscriber2}
    end

    test "GET /admin/subscribers", %{conn: conn, subscriber1: subscriber1, subscriber2: subscriber2} do
      conn = get(conn, admin_subscriber_path(conn, :index))

      assert html_response(conn, 200) =~ "Subscribers"
      assert html_response(conn, 200) =~ subscriber1.email
      assert html_response(conn, 200) =~ subscriber2.email
      assert html_response(conn, 200) =~ subscriber1.phone_number
      assert html_response(conn, 200) =~ subscriber2.phone_number
      assert html_response(conn, 200) =~ "Active"
      assert html_response(conn, 200) =~ "Disabled"
    end

    test "GET /admin/subscribers with search matches email", %{conn: conn, subscriber1: subscriber1, subscriber2: subscriber2} do
      conn = get(conn, admin_subscriber_path(conn, :index), search: "this")

      assert html_response(conn, 200) =~ "Subscribers"
      assert html_response(conn, 200) =~ subscriber1.email
      refute html_response(conn, 200) =~ subscriber2.email
      assert html_response(conn, 200) =~ subscriber1.phone_number
      refute html_response(conn, 200) =~ subscriber2.phone_number
      assert html_response(conn, 200) =~ "Active"
      refute html_response(conn, 200) =~ "Disabled"
    end

    test "GET /admin/subscribers with search matches phone number", %{conn: conn, subscriber1: subscriber1, subscriber2: subscriber2} do
      conn = get(conn, admin_subscriber_path(conn, :index), search: "0202")

      assert html_response(conn, 200) =~ "Subscribers"
      refute html_response(conn, 200) =~ subscriber1.email
      assert html_response(conn, 200) =~ subscriber2.email
      refute html_response(conn, 200) =~ subscriber1.phone_number
      assert html_response(conn, 200) =~ subscriber2.phone_number
      refute html_response(conn, 200) =~ "Active"
      assert html_response(conn, 200) =~ "Disabled"
    end

    test "GET /admin/subscribers with search doesnt match empty string", %{conn: conn, subscriber1: subscriber1, subscriber2: subscriber2} do
      conn = get(conn, admin_subscriber_path(conn, :index), search: "")

      assert html_response(conn, 200) =~ "Subscribers"
      assert html_response(conn, 200) =~ subscriber1.email
      assert html_response(conn, 200) =~ subscriber2.email
      assert html_response(conn, 200) =~ subscriber1.phone_number
      assert html_response(conn, 200) =~ subscriber2.phone_number
      assert html_response(conn, 200) =~ "Active"
      assert html_response(conn, 200) =~ "Disabled"
    end

    test "GET /admin/subscribers/:id", %{conn: conn, subscriber1: subscriber} do
      conn = get(conn, admin_subscriber_path(conn, :show, subscriber))

      assert html_response(conn, 200) =~ subscriber.email
    end
  end

  describe "regular user" do
    test "GET /admin/subscribers", %{conn: conn} do
      conn =
        :user
        |> insert(role: "user")
        |> guardian_login(conn)
        |> get(admin_subscriber_path(conn, :index))

      assert html_response(conn, 403) =~ "Forbidden"
    end
  end

  describe "unauthenticated" do
    test "GET /admin/subscribers", %{conn: conn} do
      conn = get(conn, admin_subscriber_path(conn, :index))

      assert html_response(conn, 302) =~ "/login/new"
    end
  end

  defp create_and_login_user(%{conn: conn}) do
    user = insert(:user, role: "customer_support")
    conn = guardian_login(user, conn, :token, %{default: Guardian.Permissions.max, admin: [:customer_support]})
    {:ok, [conn: conn, user: user]}
  end
end
