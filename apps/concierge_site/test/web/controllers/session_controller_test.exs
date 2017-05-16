defmodule ConciergeSite.Web.SessionControllerTest do
  use ConciergeSite.Web.ConnCase
  alias AlertProcessor.{Model.User, Repo}

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "GET /login", %{conn: conn} do
    conn = get(conn, "/login/new")
    assert html_response(conn, 200) =~ "Transportation alerts when you need them"
  end

  test "POST /login", %{conn: conn} do
    user = Repo.insert!(%User{email: "test@email.com",
                              role: "user",
                              encrypted_password: @encrypted_password})

    params = %{"user" => %{
      "email" => user.email,
      "password" => @password
    }}

    conn = post(conn, "/login", params)
    assert html_response(conn, 302) =~ "<a href=\"/my-subscriptions\">"
  end

  test "DELETE /login", %{conn: conn} do
    user = Repo.insert!(%User{email: "test@email.com",
                              role: "user",
                              encrypted_password: @encrypted_password})
    conn = user
    |> guardian_login(conn)
    |> delete("/login")

    assert html_response(conn, 302) =~ "login/new"
  end
end
