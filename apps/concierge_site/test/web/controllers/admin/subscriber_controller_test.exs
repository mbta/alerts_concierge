defmodule ConciergeSite.Admin.SubscriberControllerTest do
  use ConciergeSite.ConnCase
  use Bamboo.Test

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

    test "GET /admin/subscribers/:id/new_message", %{conn: conn, subscriber1: subscriber1} do
      conn = get(conn, admin_subscriber_subscriber_path(conn, :new_message, subscriber1))

      assert html_response(conn, 200) =~ "Create Test Message"
      assert html_response(conn, 200) =~ subscriber1.email
    end

    test "POST /admin/subscribers/:id/new_message", %{conn: conn, subscriber1: subscriber1} do
      message_params = %{"targeted_message" => %{
        "carrier" => "email",
        "subscriber_email" => subscriber1.email,
        "subject" => "Test Subject",
        "email_body" => "This is the body of the email"
      }}

      post(conn, admin_subscriber_subscriber_path(conn, :send_message, subscriber1, message_params))

      assert_delivered_with(to: [{nil, "this@email.com"}])
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

    test "GET /admin/subscribers/:id/new_message", %{conn: conn} do
      subscriber = insert(:user, email: "this@email.com", phone_number: "5551231234")
      conn =
        :user
        |> insert(role: "user")
        |> guardian_login(conn)
        |> get(admin_subscriber_subscriber_path(conn, :new_message, subscriber))

      assert html_response(conn, 403) =~ "Forbidden"
    end

    test "POST /admin/subscribers/:id/new_message", %{conn: conn} do
      subscriber = insert(:user, email: "this@email.com", phone_number: "5551231234")
      message_params = %{"targeted_message" => %{
        "carrier" => "email",
        "subscriber_email" => subscriber.email,
        "subject" => "Test Subject",
        "email_body" => "This is the body of the email"
      }}

      conn =
        :user
        |> insert(role: "user")
        |> guardian_login(conn)

      conn = post(conn, admin_subscriber_subscriber_path(conn, :send_message, subscriber, message_params))
      assert html_response(conn, 403) =~ "Forbidden"
    end
  end

  describe "unauthenticated" do
    test "GET /admin/subscribers", %{conn: conn} do
      conn = get(conn, admin_subscriber_path(conn, :index))

      assert html_response(conn, 302) =~ "/login/new"
    end

    test "GET /admin/subscribers/:id/new_message", %{conn: conn} do
      subscriber = insert(:user, email: "this@email.com", phone_number: "5551231234")
      conn = get(conn, admin_subscriber_subscriber_path(conn, :new_message, subscriber))

      assert html_response(conn, 302) =~ "/login/new"
    end

    test "POST /admin/subscribers/:id/new_message", %{conn: conn} do
      subscriber = insert(:user, email: "this@email.com", phone_number: "5551231234")
      message_params = %{"targeted_message" => %{
        "carrier" => "email",
        "subscriber_email" => subscriber.email,
        "subject" => "Test Subject",
        "email_body" => "This is the body of the email"
      }}

      conn = post(conn, admin_subscriber_subscriber_path(conn, :send_message, subscriber, message_params))

      assert html_response(conn, 302) =~ "/login/new"
    end
  end

  defp create_and_login_user(%{conn: conn}) do
    user = insert(:user, role: "customer_support")
    conn = guardian_login(user, conn, :token, @customer_support_token_params)
    {:ok, [conn: conn, user: user]}
  end
end
