defmodule ConciergeSite.Admin.SubscriberControllerTest do
  use ConciergeSite.ConnCase
  use Bamboo.Test
  alias AlertProcessor.Repo

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
      assert html_response(conn, 200) =~ "No Subscriptions"
      assert html_response(conn, 200) =~ "No Notification"
    end

    test "GET /admin/subscribers/:id with notificaitons", %{conn: conn, subscriber1: subscriber, subscriber2: other_subscriber} do
      insert(:notification, send_after: DateTime.utc_now(), status: :sent, alert_id: "123", email: "notification_email1@example.com", user: subscriber, service_effect: "Service Effect", header: "Notification Header", description: "Notification Description")
      insert(:notification, send_after: DateTime.utc_now(), status: :sent, alert_id: "456", email: "notification_email1@example.com", phone_number: "5551231234", user: subscriber, service_effect: "Service SMS Effect", header: "Notification SMS Header", description: "Notification SMS Description")
      insert(:notification, send_after: DateTime.utc_now(), status: :failed, alert_id: "789", email: "notification_email1@example.com", user: subscriber, service_effect: "Service Failed Effect", header: "Notification Failed Header", description: "Notification Failed Description")
      insert(:notification, send_after: DateTime.utc_now(), status: :sent, alert_id: "101", email: "notification_email3@example.com", user: other_subscriber, service_effect: "Service Other Subscriber Effect", header: "Notification Other Subscriber Header", description: "Notification Other Subscriber Description")

      conn = get(conn, admin_subscriber_path(conn, :show, subscriber))

      assert html_response(conn, 200) =~ subscriber.email
      assert html_response(conn, 200) =~ "No Subscriptions"
      refute html_response(conn, 200) =~ "No Notification"
      assert html_response(conn, 200) =~ "Service Effect"
      assert html_response(conn, 200) =~ "Notification Header"
      assert html_response(conn, 200) =~ "Notification Description"
      assert html_response(conn, 200) =~ "Email"
      assert html_response(conn, 200) =~ "Service SMS Effect"
      assert html_response(conn, 200) =~ "Notification SMS Header"
      assert html_response(conn, 200) =~ "Notification SMS Description"
      refute html_response(conn, 200) =~ "Failed"
      refute html_response(conn, 200) =~ "Other Subscriber"
    end

    test "GET /admin/subscribers/:id with subscriptions", %{conn: conn, subscriber1: subscriber} do
      :subscription
      |> build(user: subscriber)
      |> weekday_subscription()
      |> subway_subscription()
      |> Repo.preload(:informed_entities)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:informed_entities, subway_subscription_entities())
      |> Repo.insert()

      conn = get(conn, admin_subscriber_path(conn, :show, subscriber))

      assert html_response(conn, 200) =~ subscriber.email
      refute html_response(conn, 200) =~ "No Subscriptions"
      assert html_response(conn, 200) =~ "No Notification"
      assert html_response(conn, 200) =~ "Davis"
      assert html_response(conn, 200) =~ "Harvard"
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

      assert html_response(conn, 403) =~ "Your stop requires admin permission. This page is forbidden."
    end

    test "GET /admin/subscribers/:id/new_message", %{conn: conn} do
      subscriber = insert(:user, email: "this@email.com", phone_number: "5551231234")
      conn =
        :user
        |> insert(role: "user")
        |> guardian_login(conn)
        |> get(admin_subscriber_subscriber_path(conn, :new_message, subscriber))

      assert html_response(conn, 403) =~ "Your stop requires admin permission. This page is forbidden."
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
      assert html_response(conn, 403) =~ "Your stop requires admin permission. This page is forbidden."
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
