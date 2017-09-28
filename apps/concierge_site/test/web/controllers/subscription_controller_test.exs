defmodule ConciergeSite.SubscriptionControllerTest do
  use ConciergeSite.ConnCase

  import AlertProcessor.Factory
  import Ecto.Query
  alias AlertProcessor.{HoldingQueue, Model, Repo}
  alias Model.{InformedEntity, Subscription}

  describe "authorized" do
    test "GET /my-subscriptions", %{conn: conn}  do
      user = insert(:user)

      :subscription
      |> build(user: user)
      |> weekday_subscription()
      |> subway_subscription()
      |> Repo.preload(:informed_entities)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:informed_entities, subway_subscription_entities())
      |> Repo.insert()

      :subscription
      |> build(user: user)
      |> weekday_subscription()
      |> commuter_rail_subscription()
      |> Repo.preload(:informed_entities)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:informed_entities, commuter_rail_subscription_entities())
      |> Repo.insert()

      :subscription
      |> build(user: user)
      |> weekday_subscription()
      |> ferry_subscription()
      |> Repo.preload(:informed_entities)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:informed_entities, ferry_subscription_entities())
      |> Repo.insert()

      conn = user
      |> guardian_login(conn)
      |> get(subscription_path(conn, :index))

      assert html_response(conn, 200) =~ "My Subscriptions"
      assert html_response(conn, 200) =~ "Subway"
      assert html_response(conn, 200) =~ "Davis"
      assert html_response(conn, 200) =~ "Harvard"

      assert html_response(conn, 200) =~ "Commuter Rail"
      assert html_response(conn, 200) =~ "Anderson/Woburn"
      assert html_response(conn, 200) =~ "North Station"
      assert html_response(conn, 200) =~ "Train 331, Weekdays | Departs North Station at 5:10pm"
      assert html_response(conn, 200) =~ "Train 221, Weekdays | Departs North Station at 6:55pm"

      assert html_response(conn, 200) =~ "Ferry"
      assert html_response(conn, 200) =~ "Boston (Long Wharf)"
      assert html_response(conn, 200) =~ "Charlestown (Navy Yard)"
      assert html_response(conn, 200) =~ "5:00pm, Weekdays | Departs from Boston (Long Wharf)"
      assert html_response(conn, 200) =~ "5:15pm, Weekdays | Departs from Boston (Long Wharf)"
    end

    test "GET /my-subscriptions with bus subscriptions", %{conn: conn} do
      user = insert(:user)

      insert_bus_subscription_for_user(user)

      conn =
        user
        |> guardian_login(conn)
        |> get(subscription_path(conn, :index))

      assert html_response(conn, 200) =~ "My Subscriptions"
      assert html_response(conn, 200) =~ "57A"
      assert html_response(conn, 200) =~ "Outbound"
    end

    test "GET /my-subscriptions with amenity subscriptions", %{conn: conn} do
      user = insert(:user)
      amenity_entities = [
        %InformedEntity{route_type: 4, facility_type: :elevator, route: "Green"},
        %InformedEntity{route_type: 4, facility_type: :escalator, stop: "place-nqncy"}
      ]

      :subscription
      |> build(user: user)
      |> weekday_subscription()
      |> amenity_subscription()
      |> Repo.preload(:informed_entities)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:informed_entities, amenity_entities)
      |> Repo.insert()

      conn =
        user
        |> guardian_login(conn)
        |> get(subscription_path(conn, :index))

      assert html_response(conn, 200) =~ "My Subscriptions"
      assert html_response(conn, 200) =~ "1 station + Green Line on Weekdays"
      assert html_response(conn, 200) =~ "Escalator"
      assert html_response(conn, 200) =~ "Elevator"
    end

    test "GET /my-subscriptions redirects if no subscriptions", %{conn: conn}  do
      user = insert(:user)

      conn =
        user
        |> guardian_login(conn)
        |> get(subscription_path(conn, :index))

      assert redirected_to(conn, 302) =~ subscription_path(conn, :new)
    end

    test "GET /subscriptions/new", %{conn: conn}  do
      user = insert(:user)

      conn =
        user
        |> guardian_login(conn)
        |> get(subscription_path(conn, :new))

      assert html_response(conn, 200) =~ "Create New Subscription"
    end

    test "GET /subscriptions/new has 'Edit Station Amenities' link if user already has one amenity", %{conn: conn} do
      user = insert(:user)
      amenity_entity = [
        %InformedEntity{route_type: 4, facility_type: :elevator, route: "Green"}
      ]

      :subscription
      |> build(user: user)
      |> weekday_subscription()
      |> amenity_subscription()
      |> Repo.preload(:informed_entities)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:informed_entities, amenity_entity)
      |> Repo.insert()

      conn =
        user
        |> guardian_login(conn)
        |> get(subscription_path(conn, :new))

      assert html_response(conn, 200) =~ "Edit Station Amenities"
    end

    test "GET /subscriptions/:id/confirm_delete with a user who owns the subscription", %{conn: conn} do
      user = insert(:user)
      {:ok, subscription} = insert_bus_subscription_for_user(user)

      conn = user
      |> guardian_login(conn)
      |> get(subscription_path(conn, :confirm_delete, subscription))

      assert html_response(conn, 200) =~ "Delete Subscription?"
    end

    test "GET /subscriptions/:id/confirm_delete with a user who does not own the subscription", %{conn: conn} do
      user = insert(:user)
      other_user = insert(:user)

      {:ok, subscription} = insert_bus_subscription_for_user(other_user)
      conn = guardian_login(user, conn)

      response = assert_error_sent 404, fn ->
        get(conn, subscription_path(conn, :confirm_delete, subscription))
      end
      assert {404, _, html_response} = response
      assert html_response =~ "Your stop cannot be found. This page is no longer in service."
    end

    test "DELETE /subscriptions/:id with a user who owns the subscription", %{conn: conn} do
      user = insert(:user)
      {:ok, subscription} = insert_bus_subscription_for_user(user)
      notification = build(:notification, user_id: user.id, send_after: DateTime.from_unix!(4_078_579_247))
      :ok = HoldingQueue.enqueue(notification)

      conn = user
      |> guardian_login(conn)
      |> delete(subscription_path(conn, :delete, subscription))

      informed_entity_count = Repo.one(from i in InformedEntity, select: count("*"))
      subscription_count = Repo.one(from s in Subscription, select: count("*"))

      assert html_response(conn, 302) =~ "/my-subscriptions"
      assert subscription_count == 0
      assert informed_entity_count == 0
      assert :error = HoldingQueue.pop()
    end

    test "DELETE /subscriptions/:id with a user who does not own the subscription", %{conn: conn} do
      user = insert(:user)
      other_user = insert(:user)

      {:ok, subscription} = insert_bus_subscription_for_user(other_user)
      conn = guardian_login(user, conn)

      response = assert_error_sent 404, fn ->
        delete(conn, subscription_path(conn, :delete, subscription))
      end
      assert {404, _, html_response} = response
      assert html_response =~ "Your stop cannot be found. This page is no longer in service."

      informed_entity_count = Repo.one(from i in InformedEntity, select: count("*"))
      subscription_count = Repo.one(from s in Subscription, select: count("*"))

      assert subscription_count == 1
      assert informed_entity_count == 3
    end
  end

  describe "unauthorized" do
    test "GET /my-subscriptions", %{conn: conn} do
      conn = get(conn, subscription_path(conn, :index))
      assert html_response(conn, 302) =~ "/login"
    end

    test "GET /subscriptions/new", %{conn: conn} do
      conn = get(conn, subscription_path(conn, :new))
      assert html_response(conn, 302) =~ "/login"
    end

    test "DELETE /subscriptions/:id", %{conn: conn} do
      user = insert(:user)
      {:ok, subscription} = insert_bus_subscription_for_user(user)

      conn = delete(conn, subscription_path(conn, :delete, subscription))

      informed_entity_count = Repo.one(from i in InformedEntity, select: count("*"))
      subscription_count = Repo.one(from s in Subscription, select: count("*"))

      assert html_response(conn, 302) =~ "/login/new"
      assert subscription_count == 1
      assert informed_entity_count == 3
    end

    test "GET /subscriptions/:id/confirm_delete", %{conn: conn} do
      user = insert(:user)
      {:ok, subscription} = insert_bus_subscription_for_user(user)

      conn = get(conn, subscription_path(conn, :confirm_delete, subscription))

      assert html_response(conn, 302) =~ "/login/new"
    end
  end

  defp insert_bus_subscription_for_user(user) do
    :subscription
    |> build(user: user)
    |> weekday_subscription()
    |> bus_subscription()
    |> Repo.preload(:informed_entities)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:informed_entities, bus_subscription_entities())
    |> Repo.insert()
  end
end
