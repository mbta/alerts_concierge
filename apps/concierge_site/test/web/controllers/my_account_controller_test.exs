defmodule ConciergeSite.MyAccountControllerTest do
  use ConciergeSite.ConnCase
  alias AlertProcessor.{HoldingQueue, Model, Repo}
  alias Model.User

  describe "authorized" do
    setup :insert_user

    test "GET /my-account/edit", %{conn: conn, user: user} do
      conn = user
      |> guardian_login(conn)
      |> get("/my-account/edit")

      assert html_response(conn, 200) =~ "My Account"
    end

    test "PATCH /my-account/ with valid params", %{conn: conn, user: user} do
      notification = build(:notification, user_id: user.id, send_after: DateTime.from_unix!(4_078_579_247))
      :ok = HoldingQueue.enqueue(notification)
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

      assert html_response(conn, 302) =~ "my-subscriptions"
      assert updated_user.phone_number == "5551234567"
      assert updated_user.do_not_disturb_end == ~T[18:30:00.000000]
      assert updated_user.do_not_disturb_start == ~T[16:30:00.000000]
      assert updated_user.amber_alert_opt_in == false
      assert :error = HoldingQueue.pop()
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
      conn = user
      |> guardian_login(conn)
      |> delete(my_account_path(conn, :delete))

      updated_user = Repo.get(User, user.id)

      assert html_response(conn, 302) =~ "/account_disabled"
      assert updated_user.encrypted_password == ""
      refute is_nil(updated_user.vacation_start)
      assert DateTime.compare(updated_user.vacation_end, DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC")) == :eq
    end

    test "DELETE /my-account with valid token", %{conn: conn, user: user} do
      conn = user
      |> guardian_login(conn, :access, %{default: [:disable_account]})
      |> delete(my_account_path(conn, :delete))

      updated_user = Repo.get(User, user.id)

      assert html_response(conn, 302) =~ "/account_disabled"
      assert updated_user.encrypted_password == ""
      refute is_nil(updated_user.vacation_start)
      assert DateTime.compare(updated_user.vacation_end, DateTime.from_naive!(~N[9999-12-25 23:59:59], "Etc/UTC")) == :eq
    end

    test "DELETE /my-account without valid token", %{conn: conn, user: user} do
      conn = user
      |> guardian_login(conn, :access, %{default: [:unsubscribe]})
      |> delete(my_account_path(conn, :delete))

      updated_user = Repo.get(User, user.id)

      assert html_response(conn, 302) =~ "/login"
      refute updated_user.encrypted_password == ""
      assert is_nil(updated_user.vacation_start)
      assert is_nil(updated_user.vacation_end)
    end

    test "GET /my-account/confirm_disable", %{conn: conn, user: user} do
      conn = user
      |> guardian_login(conn)
      |> get(my_account_path(conn, :confirm_disable))

      assert html_response(conn, 200) =~ "Disable Account?"
    end

    test "GET /my-account/confirm_disable with valid token", %{conn: conn, user: user} do
      {:ok, token, _} = ConciergeSite.Auth.Token.issue(user, [:disable_account])
      conn = get(conn, my_account_path(conn, :confirm_disable, token: token))
      assert html_response(conn, 200) =~ "Disable Account?"
    end

    test "GET /my-account/confirm_disable without valid token", %{conn: conn} do
      conn = get(conn, my_account_path(conn, :confirm_disable, token: "notatoken"))
      assert html_response(conn, 302) =~ "/login"
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

    test "GET /my-account/confirm_disable", %{conn: conn} do
      conn = get(conn, my_account_path(conn, :confirm_disable))
      assert html_response(conn, 302) =~ "/login"
    end
  end

  defp insert_user(_context) do
    {:ok, [user: insert(:user)]}
  end
end
