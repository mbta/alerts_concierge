defmodule ConciergeSite.PasswordResetControllerTest do
  use ConciergeSite.ConnCase
  use Bamboo.Test
  import Ecto.Query
  alias AlertProcessor.{Model, Repo}
  alias Model.{PasswordReset, User}
  alias ConciergeSite.Email

  test "GET /reset-password/new", %{conn: conn}  do
    conn = get(conn, password_reset_path(conn, :new))
    assert html_response(conn, 200) =~ "Forget your password?"
  end

  test "POST /reset-password/ with an email associated with a user", %{conn: conn}  do
    user = insert(:user)
    params = %{"password_reset" => %{"email" => user.email}}
    conn = post(conn, password_reset_path(conn, :create), params)

    password_reset_count = Repo.one(from p in PasswordReset, select: count("*"))
    password_reset = Repo.one(PasswordReset)

    assert password_reset_count == 1
    assert html_response(conn, 302) =~ "/reset-password/sent"
    assert_delivered_email Email.password_reset_html_email(user.email, password_reset.id)
  end

  test "POST /reset-password/ with a valid but unknown email", %{conn: conn}  do
    email = "test@example.com"
    params = %{"password_reset" => %{"email" => email}}
    conn = post(conn, password_reset_path(conn, :create), params)

    password_reset_count = Repo.one(from p in PasswordReset, select: count("*"))

    assert password_reset_count == 0
    assert html_response(conn, 302) =~ "/reset-password/sent"
    assert_delivered_email Email.unknown_password_reset_html_email(email)
  end

  test "POST /reset-password/ with an invalid email", %{conn: conn}  do
    params = %{"password_reset" => %{"email" => "blerg"}}
    conn = post(conn, password_reset_path(conn, :create), params)

    password_reset_count = Repo.one(from p in PasswordReset, select: count("*"))

    assert password_reset_count == 0
    assert html_response(conn, 200) =~ "Email is not in a valid format."
  end

  test "GET /reset-password/:id/edit with a redeemable Password Reset", %{conn: conn}  do
    password_reset = insert(:password_reset)
    conn = get(conn, password_reset_path(conn, :edit, password_reset))

    assert html_response(conn, 200) =~ "Enter and confirm your new password below."
  end

  test "GET /reset-password/:id/edit with an expired password reset", %{conn: conn}  do
    password_reset = insert(:password_reset, expired_at: DateTime.subtract!(DateTime.now_utc, 1))

    assert_raise Ecto.NoResultsError, fn ->
      get(conn, password_reset_path(conn, :edit, password_reset))
    end
  end

  test "GET /reset-password/:id/edit with a redeemed password reset", %{conn: conn}  do
    password_reset = insert(:password_reset, redeemed_at: DateTime.subtract!(DateTime.now_utc, 1))

    assert_raise Ecto.NoResultsError, fn ->
      get(conn, password_reset_path(conn, :edit, password_reset))
    end
  end
end
