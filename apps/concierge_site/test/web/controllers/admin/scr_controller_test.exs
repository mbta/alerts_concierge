defmodule ConciergeSite.Admin.ScrControllerTest do
  use ConciergeSite.ConnCase, async: true
  alias AlertProcessor.Model.NotificationSubscription
  alias AlertProcessor.Model.Subscription
  alias AlertProcessor.Repo
  alias ConciergeSite.Admin.ScrController

  setup %{conn: conn} do
    user = insert(:user, role: "admin")
    conn = guardian_login(user, conn)

    {:ok, user: user, conn: conn}
  end

  describe "index" do
    test "lists counts on old and new routes", %{conn: conn} do
      trip = insert(:trip)

      insert_list(13, :subscription, trip_id: trip.id, route: "CR-Middleborough")
      insert_list(12, :subscription, trip_id: trip.id, route: "CR-NewBedford")

      conn = get(conn, admin_scr_path(conn, :index))

      assert html_response(conn, 200) =~ "13 Middleborough/Lakeville Line subscriptions"
      assert html_response(conn, 200) =~ "12 Fall River/New Bedford Line subscriptions"
    end

    test "warns on phase 2 if more old subscriptions than new", %{conn: conn} do
      trip = insert(:trip)

      insert_list(8, :subscription, trip_id: trip.id, route: "CR-Middleborough")
      insert_list(2, :subscription, trip_id: trip.id, route: "CR-NewBedford")

      conn = get(conn, admin_scr_path(conn, :index))

      assert html_response(conn, 200) =~
               "That’s more than the 2 Fall River/New Bedford Line subscriptions!"
    end

    test "only available to admins", %{conn: conn} do
      conn = guardian_login(insert(:user, role: "user"), conn)

      conn = get(conn, admin_scr_path(conn, :index))

      assert redirected_to(conn) == "/trips"
    end
  end

  describe "phase1" do
    test "copies subscriptions and notifications if needed", %{conn: conn} do
      [trip1, trip2] = insert_list(2, :trip)

      sub11 = insert(:subscription, trip: trip1, route: "CR-Middleborough")

      sub11after =
        insert(:subscription,
          id: ScrController.uuid_op(sub11.id, &(&1 + 1)),
          trip: trip1,
          route: "CR-NewBedford"
        )

      sub12 = insert(:subscription, trip: trip1, route: "CR-Middleborough")
      [sub21, sub22] = insert_list(2, :subscription, trip: trip2, route: "CR-Middleborough")

      alert = insert(:saved_alert)

      [notif1, notif2] = insert_list(2, :notification, alert_id: alert.id, status: :sent)

      insert(:notification_subscription, notification: notif1, subscription: sub11)
      insert(:notification_subscription, notification: notif1, subscription: sub11after)
      insert(:notification_subscription, notification: notif1, subscription: sub12)
      insert(:notification_subscription, notification: notif2, subscription: sub21)
      insert(:notification_subscription, notification: notif2, subscription: sub22)

      conn = post(conn, admin_scr_path(conn, :phase1))
      assert redirected_to(conn) == admin_scr_path(conn, :index)

      [sub11id, sub11afterid, sub12id, sub21id, sub22id] =
        [sub11, sub11after, sub12, sub21, sub22] |> Enum.map(& &1.id)

      [sub12afterid, sub21afterid, sub22afterid] =
        [sub12id, sub21id, sub22id]
        |> Enum.map(fn id_before -> ScrController.uuid_op(id_before, &(&1 + 1)) end)

      assert %{
               ^sub11id => %Subscription{},
               ^sub11afterid => %Subscription{},
               ^sub12id => %Subscription{},
               ^sub12afterid => %Subscription{},
               ^sub21id => %Subscription{},
               ^sub21afterid => %Subscription{},
               ^sub22id => %Subscription{},
               ^sub22afterid => %Subscription{}
             } = Repo.all(Subscription) |> Map.new(&{&1.id, &1})

      all_ns = Repo.all(NotificationSubscription)

      assert MapSet.new([sub11id, sub11afterid, sub12id, sub12afterid]) ==
               all_ns
               |> Enum.filter(&(&1.notification_id == notif1.id))
               |> MapSet.new(& &1.subscription_id)

      assert MapSet.new([sub21id, sub21afterid, sub22id, sub22afterid]) ==
               all_ns
               |> Enum.filter(&(&1.notification_id == notif2.id))
               |> MapSet.new(& &1.subscription_id)

      assert get_flash(conn, :info) ==
               "Migrated 3 subscriptions and 3 associations to notifications."
    end

    test "only available to admins", %{conn: conn} do
      conn = guardian_login(insert(:user, role: "user"), conn)

      conn = post(conn, admin_scr_path(conn, :phase1))

      assert redirected_to(conn) == "/trips"
    end
  end

  describe "phase2" do
    test "deletes old subscriptions and notification deliveries", %{conn: conn} do
      trip = insert(:trip)

      sub_before = insert(:subscription, trip: trip, route: "CR-Middleborough")

      sub_after =
        insert(:subscription,
          id: ScrController.uuid_op(sub_before.id, &(&1 + 1)),
          trip: trip,
          route: "CR-NewBedford"
        )

      alert = insert(:saved_alert)
      notif = insert(:notification, alert_id: alert.id, status: :sent)

      insert(:notification_subscription, notification: notif, subscription: sub_before)
      insert(:notification_subscription, notification: notif, subscription: sub_after)

      conn = post(conn, admin_scr_path(conn, :phase2))
      assert redirected_to(conn) == admin_scr_path(conn, :index)

      assert Repo.one!(Subscription).id == sub_after.id
      assert Repo.one!(NotificationSubscription).subscription_id == sub_after.id

      assert get_flash(conn, :info) ==
               "Deleted 1 subscriptions and 1 associations to notifications."
    end

    test "only available to admins", %{conn: conn} do
      conn = guardian_login(insert(:user, role: "user"), conn)

      conn = post(conn, admin_scr_path(conn, :phase2))

      assert redirected_to(conn) == "/trips"
    end
  end
end
