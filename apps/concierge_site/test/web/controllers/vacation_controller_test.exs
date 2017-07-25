defmodule ConciergeSite.VacationControllerTest do
  use ConciergeSite.ConnCase
  import AlertProcessor.Factory
  alias AlertProcessor.{HoldingQueue, Model, Repo}
  alias Model.User


  describe "authorized" do
    setup :create_and_login_user

    test "GET /my-account/vacation/edit", %{conn: conn} do
      conn = get(conn, my_account_vacation_path(conn, :edit))

      assert html_response(conn, 200) =~ "Pause T-Alerts"
    end

    test "PATCH /my-account/vacation with a valid submission", %{conn: conn, user: user} do
      notification = build(:notification, user_id: user.id, send_after: DateTime.from_unix!(4_078_579_247))
      :ok = HoldingQueue.enqueue(notification)
      params = %{"user" => %{
        "vacation_start" => "09/01/2017",
        "vacation_end" => "09/01/2035"
      }}

      conn = patch(conn, my_account_vacation_path(conn, :update, params))

      updated_user = Repo.get(User, user.id)

      assert html_response(conn, 302) =~ subscription_path(conn, :index)
      assert :eq = NaiveDateTime.compare(updated_user.vacation_start, ~N[2017-09-01 00:00:00])
      assert :eq = NaiveDateTime.compare(updated_user.vacation_end, ~N[2035-09-01 00:00:00])
      assert :error = HoldingQueue.pop()
    end

    test "PATCH /my-account/vacation with vacation_end in past", %{conn: conn, user: user} do
      params = %{"user" => %{
        "vacation_start" => "09/01/2014",
        "vacation_end" => "09/01/2015"
      }}

      conn = patch(conn, my_account_vacation_path(conn, :update, params))

      updated_user = Repo.get(User, user.id)

      assert html_response(conn, 200) =~ "Vacation period must end sometime in the future"
      assert updated_user.vacation_start == nil
      assert updated_user.vacation_end == nil
    end

    test "DELETE /my-account/vacation", %{conn: conn} do
      user = insert(:user, vacation_start: ~N[2017-07-01 00:00:00.00], vacation_end: ~N[2117-07-01 00:00:00.00])
      conn = guardian_login(user, conn)
      conn = delete(conn, my_account_vacation_path(conn, :delete))

      updated_user = Repo.get(User, user.id)

      assert html_response(conn, 302) =~ "/my-subscriptions"
      assert updated_user.vacation_start == nil
      assert updated_user.vacation_end == nil
      assert_received :opt_in_phone_number
    end
  end

  describe "unauthorized" do
    test "GET /my-account/vacation/edit", %{conn: conn} do
      conn = get(conn, my_account_vacation_path(conn, :edit))
      assert html_response(conn, 302) =~ session_path(conn, :new)
    end

    test "PATCH /my-account/vacation", %{conn: conn} do
      params = %{"user" => %{
        "vacation_start" => "09/01/2035",
        "vacation_end" => "09/01/2017"
      }}

      conn = patch(conn, my_account_vacation_path(conn, :update, params))
      assert html_response(conn, 302) =~ session_path(conn, :new)
    end
  end

  defp create_and_login_user(%{conn: conn}) do
    user = insert(:user)
    conn = guardian_login(user, conn)
    {:ok, [conn: conn, user: user]}
  end
end
