defmodule ConciergeSite.Admin.SubscriptionSearchControllerTest do
  use ConciergeSite.ConnCase

  alias AlertProcessor.{Model.Subscription, Repo}

  setup do
    subscriber = insert(:user, email: "this@email.com", phone_number: "5551231234")
    {:ok, subscriber: subscriber}
  end

  describe "authorized" do
    setup :create_and_login_user

    test "GET /admin/subscription_search/:id/new loads search page for admin", %{conn: conn, subscriber: subscriber} do
      conn = get(conn, admin_subscription_search_path(conn, :new, subscriber.id))

      assert html_response(conn, 200) =~ "Search by Alert"
    end

    test "GET /admin/subscription_search/:id/new with invalid user_id", %{conn: conn} do
      conn = get(conn, admin_subscription_search_path(conn, :new, "70d2b710-5a86-40e3-a5b4-ebd14e7866fc"))

      assert html_response(conn, 302) =~ "/admin_users"
    end

    test "POST /admin/subscription_search/:id returns all subscriptions for a given date", %{conn: conn, subscriber: subscriber} do
      {:ok, future_date, _} = DateTime.from_iso8601("2118-01-01T01:01:01Z")
      {:ok, date, _} = DateTime.from_iso8601("2017-07-11T01:01:01Z")
      sub_params = params_for(
        :subscription,
        user: subscriber,
        updated_at: date,
        inserted_at: date,
        relevant_days: [:sunday]
      )
      create_changeset = Subscription.create_changeset(%Subscription{}, sub_params)
      inserted_sub = PaperTrail.insert!(create_changeset)
      {:ok, _updated_sub} = Subscription.update_subscription(inserted_sub, %{
        updated_at: future_date
      }, subscriber.id)

      # update papertrail version dates
      [insert_version, update_version] = PaperTrail.get_versions(inserted_sub)
      insert_changeset = Ecto.Changeset.cast(insert_version, %{inserted_at: date}, [:inserted_at])
      update_changeset = Ecto.Changeset.cast(update_version, %{inserted_at: future_date}, [:inserted_at])

      Repo.update!(insert_changeset)
      Repo.update!(update_changeset)

      params = %{
        "search" => %{
          "alert_id" => "70d2b710-5a86-40e3-a5b4-ebd14e7866fc",
          "alert_date" => %{
            "year" => "2017",
            "month" => "07",
            "day" => "11",
            "hour" => "11",
            "min" => "11"
          }
        }
      }

      conn = post(conn, admin_subscription_search_path(conn, :create, subscriber.id), params)
      assert html_response(conn, 200)

      # TODO: Need to update this once we know what is actually rendered for each sub
      # response = html_response(conn, 200)
      # assert response =~ inserted_sub.id
    end
  end

  describe "unauthorized" do
    test "GET /admin/subscription_search/:id/new without admin role", %{subscriber: subscriber} do
      conn = build_conn()
      conn = guardian_login(subscriber, conn, :token)
      conn = get(conn, admin_subscription_search_path(conn, :new, subscriber.id))

      assert html_response(conn, 403)
    end

    test "POST /admin/subscription_search/:id without admin role", %{subscriber: subscriber} do
      conn = build_conn()
      conn = guardian_login(subscriber, conn, :token)
      conn = post(conn, admin_subscription_search_path(conn, :create, subscriber.id))

      assert html_response(conn, 403)
    end
  end

  describe "unauthenticated" do
    test "GET /admin/subscription_search/:id/new without auth", %{subscriber: subscriber} do
      conn = build_conn()
      conn = get(conn, admin_subscription_search_path(conn, :new, subscriber.id))
      assert html_response(conn, 302)
    end

    test "POST /admin/subscription_search/:id without auth", %{subscriber: subscriber} do
      conn = build_conn()
      conn = post(conn, admin_subscription_search_path(conn, :create, subscriber.id))
      assert html_response(conn, 302)
    end
  end

  defp create_and_login_user(%{conn: conn}) do
    user = insert(:user, role: "customer_support")
    conn = guardian_login(user, conn, :token, @customer_support_token_params)
    {:ok, [conn: conn, user: user]}
  end
end
