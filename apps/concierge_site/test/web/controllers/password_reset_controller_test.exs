defmodule ConciergeSite.PasswordResetControllerTest do
  use ConciergeSite.ConnCase
  import Ecto.Query
  alias AlertProcessor.{Model, Repo}
  alias Model.PasswordReset

  test "GET /reset-password/new", %{conn: conn}  do
    conn = get(conn, "/reset-password/new")
    assert html_response(conn, 200) =~ "Forget your password?"
  end

  test "GET /reset-password/new with an email associated with a user", %{conn: conn}  do
    user = insert(:user)
    params = %{"password_reset" => %{"email" => user.email}}
    conn = post(conn, "/reset-password", params)

    password_reset_count = Repo.one(from p in PasswordReset, select: count("*"))

    assert password_reset_count == 1
    assert html_response(conn, 302) =~ "/reset-password/sent"
  end

  test "GET /reset-password/new with an unknown email", %{conn: conn}  do
    params = %{"password_reset" => %{"email" => "ex@mp.le"}}
    conn = post(conn, "/reset-password", params)

    password_reset_count = Repo.one(from p in PasswordReset, select: count("*"))

    assert password_reset_count == 0
    assert html_response(conn, 302) =~ "/reset-password/sent"
  end
end
