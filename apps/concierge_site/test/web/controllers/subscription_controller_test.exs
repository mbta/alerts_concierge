defmodule ConciergeSite.SubscriptionControllerTest do
  use ConciergeSite.ConnCase

  import AlertProcessor.Factory
  alias AlertProcessor.{Model, Repo}
  alias Model.{InformedEntity}

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
    end

    test "GET /my-subscriptions with bus subscriptions", %{conn: conn} do
      user = insert(:user)

      :subscription
      |> build(user: user)
      |> weekday_subscription()
      |> bus_subscription()
      |> Repo.preload(:informed_entities)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:informed_entities, bus_subscription_entities())
      |> Repo.insert()

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
        %InformedEntity{route_type: 4, facility_type: :escalator, stop: "place-nquincy"}
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
  end
end
