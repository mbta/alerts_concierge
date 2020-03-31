defmodule ConciergeSite.PasswordResetControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true
  use Bamboo.Test

  test "new/2", %{conn: conn} do
    conn = get(conn, password_reset_path(conn, :new))
    assert html_response(conn, 200) =~ "Reset your password"
  end

  describe "create/2" do
    test "existing user can request email to reset password", %{conn: conn} do
      user = insert(:user)
      params = %{"password_reset" => %{"email" => user.email}}
      conn = post(conn, password_reset_path(conn, :create), params)
      assert html_response(conn, 302) =~ "/"
      assert get_flash(conn)["info"] == "We've sent you a password reset email. Check your inbox!"
      assert_email_delivered_with(to: [{nil, user.email}])
    end

    test "non-existent user can't request email to reset password", %{conn: conn} do
      email = "non-existing-user@domain.com"
      params = %{"password_reset" => %{"email" => email}}
      conn = post(conn, password_reset_path(conn, :create), params)
      assert html_response(conn, 200) =~ "Could not find that email address."
      refute_email_delivered_with(to: [{nil, email}])
    end

    test "lookup is not case-sensitive", %{conn: conn} do
      user = insert(:user)
      params = %{"password_reset" => %{"email" => String.capitalize(user.email)}}
      conn = post(conn, password_reset_path(conn, :create), params)
      assert html_response(conn, 302) =~ "/"
      assert get_flash(conn)["info"] == "We've sent you a password reset email. Check your inbox!"
      assert_email_delivered_with(to: [{nil, user.email}])
    end
  end

  test "edit/2", %{conn: conn} do
    conn = get(conn, password_reset_path(conn, :edit, "some-reset-token"))
    assert html_response(conn, 200) =~ "Reset Password"
  end

  describe "update/2" do
    test "with valid reset token and password", %{conn: conn} do
      user = insert(:user)
      reset_token = Phoenix.Token.sign(ConciergeSite.Endpoint, "password_reset", user.email)
      valid_password = "password1!"

      params = %{
        "password_reset" => %{
          "password" => valid_password,
          "password_confirmation" => valid_password
        }
      }

      conn = patch(conn, password_reset_path(conn, :update, reset_token), params)
      assert get_flash(conn)["info"] == "Your password has been updated."
    end

    test "with invalid reset token", %{conn: conn} do
      reset_token = "some-invalid-token"
      valid_password = "password1!"

      params = %{
        "password_reset" => %{
          "password" => valid_password,
          "password_confirmation" => valid_password
        }
      }

      conn = patch(conn, password_reset_path(conn, :update, reset_token), params)
      assert html_response(conn, 404) =~ "cannot be found"
    end

    test "with invalid password", %{conn: conn} do
      user = insert(:user)
      reset_token = Phoenix.Token.sign(ConciergeSite.Endpoint, "password_reset", user.email)
      invalid_password = "invalid"

      params = %{
        "password_reset" => %{
          "password" => invalid_password,
          "password_confirmation" => invalid_password
        }
      }

      conn = patch(conn, password_reset_path(conn, :update, reset_token), params)

      assert html_response(conn, 422) =~
               "Password must contain at least 6 characters, with one number or symbol."
    end

    test "with invalid password confirmation", %{conn: conn} do
      user = insert(:user)
      reset_token = Phoenix.Token.sign(ConciergeSite.Endpoint, "password_reset", user.email)

      params = %{
        "password_reset" => %{
          "password" => "password1!",
          "password_confirmation" => "secret1!"
        }
      }

      conn = patch(conn, password_reset_path(conn, :update, reset_token), params)
      assert html_response(conn, 422) =~ "Password confirmation must match."
    end
  end
end
