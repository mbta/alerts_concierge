defmodule ConciergeSite.AccountControllerTest do
  use ConciergeSite.ConnCase
  alias AlertProcessor.{Model, Repo}
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
  end

  describe "unauthorized" do
    test "GET /my-account/edit", %{conn: conn} do
      conn = get(conn, "/my-account/edit")
      assert html_response(conn, 302) =~ "/login"
    end
  end

  defp insert_user(_context) do
    {:ok, [user: insert(:user)]}
  end
end
