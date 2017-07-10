defmodule ConciergeSite.PasswordControllerTest do
  use ConciergeSite.ConnCase
  alias AlertProcessor.{Model, Repo}
  alias Model.User

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  describe "authorized" do
    test "GET /my-account/password/edit", %{conn: conn} do
      user = Repo.insert!(
        %User{email: "test@email.com", role: "user", encrypted_password: @encrypted_password}
      )

      conn = user
      |> guardian_login(conn)
      |> get("/my-account/password/edit")

      assert html_response(conn, 200) =~ "Change Password"
    end

    test "PATCH /my-account/password with a valid submission", %{conn: conn} do
      user = Repo.insert!(
        %User{email: "test@email.com", role: "user", encrypted_password: @encrypted_password}
      )

      params = %{"user" => %{
        "current_password" => "password1",
        "password" => "P@ssword2",
        "password_confirmation" => "P@ssword2"
      }}

      conn = user
      |> guardian_login(conn)
      |> patch("my-account/password", params)

      updated_user = Repo.get(User, user.id)

      assert html_response(conn, 302) =~ "my-account/edit"
      refute updated_user.encrypted_password == @encrypted_password
    end

    test "PATCH /my-account/password with the wrong current password", %{conn: conn} do
      user = Repo.insert!(
        %User{email: "test@email.com", role: "user", encrypted_password: @encrypted_password}
      )

      params = %{"user" => %{
        "current_password" => "wrongpass2",
        "password" => "P@55w0rc!1",
        "password_confirmation" => "P@55w0rc!1"
      }}

      conn = user
      |> guardian_login(conn)
      |> patch("my-account/password", params)

      updated_user = Repo.get(User, user.id)

      assert html_response(conn, 200) =~ "Current password is incorrect."
      assert updated_user.encrypted_password == @encrypted_password
    end
  end

  describe "unauthorized" do
    test "GET /my-account/password/edit", %{conn: conn} do
      conn = get(conn, "/my-account/password/edit")
      assert html_response(conn, 302) =~ "/login"
    end
  end
end
