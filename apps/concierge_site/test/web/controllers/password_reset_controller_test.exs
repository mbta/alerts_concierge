defmodule ConciergeSite.PasswordResetControllerTest do
  use ConciergeSite.ConnCase
  use Bamboo.Test
  import Ecto.Query
  alias AlertProcessor.{Model, Repo}
  alias Model.{PasswordReset, User}
  alias ConciergeSite.Dissemination.Email
  alias Calendar.DateTime

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "GET /reset-password/new", %{conn: conn}  do
    conn = get(conn, password_reset_path(conn, :new))
    assert html_response(conn, 200) =~ "Reset your password"
  end

  test "POST /reset-password/ with an email associated with a user", %{conn: conn}  do
    user = insert(:user)
    params = %{"password_reset" => %{"email" => user.email}}
    conn = post(conn, password_reset_path(conn, :create), params)

    password_reset_count = Repo.one(from p in PasswordReset, select: count("*"))

    assert password_reset_count == 1
    assert html_response(conn, 302) =~ "/reset-password/sent"
    assert_delivered_with(to: [{nil, user.email}])
  end

  test "POST /reset-password/ with a valid but unknown email", %{conn: conn}  do
    email = "test@example.com"
    params = %{"password_reset" => %{"email" => email}}
    conn = post(conn, password_reset_path(conn, :create), params)

    password_reset_count = Repo.one(from p in PasswordReset, select: count("*"))

    assert password_reset_count == 0
    assert html_response(conn, 302) =~ "/reset-password/sent"
    assert_delivered_email Email.unknown_password_reset_email(email)
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

    response = assert_error_sent 404, fn ->
      get(conn, password_reset_path(conn, :edit, password_reset))
    end
    assert {404, _, "Page not found"} = response
  end

  test "GET /reset-password/:id/edit with a redeemed password reset", %{conn: conn}  do
    password_reset = insert(:password_reset, redeemed_at: DateTime.subtract!(DateTime.now_utc, 1))

    response = assert_error_sent 404, fn ->
      get(conn, password_reset_path(conn, :edit, password_reset))
    end
    assert {404, _, "Page not found"} = response
  end

  test "PATCH /reset-password/:id/ with a redeemable Password Reset", %{conn: conn} do
    user = insert(:user, encrypted_password: @encrypted_password)
    password_reset = insert(:password_reset, user: user)

    params = %{"user" => %{
      "password" => "P@ssword1",
      "password_confirmation" => "P@ssword1",
    }}

    conn = patch(conn, password_reset_path(conn, :update, password_reset), params)

    updated_user = Repo.get(User, user.id)
    updated_password_reset = Repo.get(PasswordReset, password_reset.id)

    assert html_response(conn, 302) =~ "/my-account/edit"
    refute updated_user.encrypted_password == @encrypted_password
    refute is_nil(updated_password_reset.redeemed_at)
  end

  test "PATCH /reset-password/:id with a redeemable Password Reset but an invalid password", %{conn: conn} do
    user = insert(:user, encrypted_password: @encrypted_password)
    password_reset = insert(:password_reset, user: user)

    params = %{"user" => %{
      "password" => "a",
      "password_confirmation" => "a",
    }}

    conn = patch(conn, password_reset_path(conn, :update, password_reset), params)

    updated_user = Repo.get(User, user.id)
    updated_password_reset = Repo.get(PasswordReset, password_reset.id)

    assert html_response(conn, 200) =~ "Password must contain one number or special character"
    assert updated_user.encrypted_password == @encrypted_password
    assert is_nil(updated_password_reset.redeemed_at)
  end

  test "PATCH /reset-password/:id with an expired Password Reset", %{conn: conn} do
    user = insert(:user, encrypted_password: @encrypted_password)
    password_reset = insert(:password_reset, user: user, expired_at: DateTime.subtract!(DateTime.now_utc(), 1))

    params = %{"user" => %{
      "password" => "P@ssword1",
      "password_confirmation" => "P@ssword1",
    }}

    response = assert_error_sent 404, fn ->
      patch(conn, password_reset_path(conn, :update, password_reset), params)
    end
    assert {404, _, "Page not found"} = response

    updated_user = Repo.get(User, user.id)
    assert updated_user.encrypted_password == @encrypted_password
  end

  test "PATCH /reset-password/:id with a redeemed Password Reset", %{conn: conn} do
    user = insert(:user, encrypted_password: @encrypted_password)
    password_reset = insert(:password_reset, user: user, redeemed_at: DateTime.now_utc())

    params = %{"user" => %{
      "password" => "P@ssword1",
      "password_confirmation" => "P@ssword1",
    }}

    response = assert_error_sent 404, fn ->
      patch(conn, password_reset_path(conn, :update, password_reset), params)
    end
    assert {404, _, "Page not found"} = response

    updated_user = Repo.get(User, user.id)
    assert updated_user.encrypted_password == @encrypted_password
  end
end
