defmodule ConciergeSite.ApiSearchControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase

  setup do
    regular_user = insert(:user)
    admin_user = insert(:user, role: "admin")

    {:ok, regular_user: regular_user, admin_user: admin_user}
  end

  describe "GET /api/search/:query" do
    test "as an admin: searches by email and phone number", %{conn: conn, admin_user: admin_user} do
      user_matching_email = insert(:user, email: "email-42@example.com", phone_number: nil)
      user_matching_phone_number = insert(:user, phone_number: "6175554255")
      _non_matching_user = insert(:user, email: "email-11111@example.com", phone_number: nil)

      conn =
        admin_user
        |> guardian_login(conn)
        |> get(api_search_path(conn, :index, "42"))

      assert json_response(conn, 200) == %{
               "users" => [
                 %{
                   "id" => user_matching_email.id,
                   "email" => user_matching_email.email,
                   "phone_number" => user_matching_email.phone_number
                 },
                 %{
                   "id" => user_matching_phone_number.id,
                   "email" => user_matching_phone_number.email,
                   "phone_number" => user_matching_phone_number.phone_number
                 }
               ]
             }
    end

    test "not as an admin: doesn't allow you to search", %{conn: conn, regular_user: regular_user} do
      conn =
        regular_user
        |> guardian_login(conn)
        |> get(api_search_path(conn, :index, "42"))

      assert html_response(conn, 302)
    end

    test "not logged in: doesn't allow you to search", %{conn: conn} do
      conn = get(conn, api_search_path(conn, :index, "42"))

      assert html_response(conn, 302)
    end
  end
end
