defmodule ConciergeSite.MyAccountControllerTest do
  use ConciergeSite.ConnCase
  alias AlertProcessor.{Model, Repo}
  alias Model.{InformedEntity, Subscription, User}
  import Ecto.Query

  describe "authorized" do
    setup :insert_user

    test "GET /my-account/edit", %{conn: conn, user: user} do
      conn = user
      |> guardian_login(conn)
      |> get("/my-account/edit")

      assert html_response(conn, 200) =~ "My Account"
    end

    test "PATCH /my-account/ with valid params", %{conn: conn, user: user} do
      params = %{"user" => %{
        "dnd_toggle" => "true",
        "do_not_disturb_start" => "16:30:00",
        "do_not_disturb_end" => "18:30:00",
        "phone_number" => "5551234567",
        "sms_toggle" => "true",
        "amber_alert_opt_in" => "false"
      }}

      conn = user
      |> guardian_login(conn)
      |> patch("/my-account", params)

      updated_user = Repo.get!(User, user.id)

      assert html_response(conn, 302) =~ "my-account/edit"
      assert updated_user.phone_number == "5551234567"
      assert updated_user.do_not_disturb_end == ~T[22:30:00.000000]
      assert updated_user.do_not_disturb_start == ~T[20:30:00.000000]
      assert updated_user.amber_alert_opt_in == false
    end

    test "PATCH /my-account/ with invalid params", %{conn: conn, user: user} do
      params = %{"user" => %{
        "dnd_toggle" => "true",
        "do_not_disturb_end" => "23:45:00",
        "do_not_disturb_start" => "19:30:00",
        "phone_number" => "abc123",
        "sms_toggle" => "true",
        "amber_alert_opt_in" => "true"
      }}

      conn = user
      |> guardian_login(conn)
      |> patch("/my-account", params)

      assert html_response(conn, 200) =~ "Account Preferences could not be updated. Please see errors below."
    end

    test "DELETE /my-account", %{conn: conn, user: user} do
      insert_bus_subscription_for_user(user)

      conn = user
      |> guardian_login(conn)
      |> delete(my_account_path(conn, :delete))

      updated_user = Repo.get(User, user.id)
      informed_entity_count = Repo.one(from i in InformedEntity, select: count("*"))
      subscription_count = Repo.one(from s in Subscription, select: count("*"))

      assert html_response(conn, 302) =~ "/login/new"
      assert subscription_count == 0
      assert informed_entity_count == 0
      assert is_nil(updated_user.encrypted_password)
    end

    test "GET /my-account/confirm_delete", %{conn: conn, user: user} do
      conn = user
      |> guardian_login(conn)
      |> get(my_account_path(conn, :confirm_delete))

      assert html_response(conn, 200) =~ "Delete Account?"
    end
  end

  describe "unauthorized" do
    test "GET /my-account/edit", %{conn: conn} do
      conn = get(conn, "/my-account/edit")
      assert html_response(conn, 302) =~ "/login"
    end

    test "DELETE /my-account", %{conn: conn} do
      conn = delete(conn, my_account_path(conn, :delete))
      assert html_response(conn, 302) =~ "/login"
    end

    test "GET /my-account/confirm_delete", %{conn: conn} do
      conn = get(conn, my_account_path(conn, :confirm_delete))
      assert html_response(conn, 302) =~ "/login"
    end
  end

  defp insert_user(_context) do
    {:ok, [user: insert(:user)]}
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
