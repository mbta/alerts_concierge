defmodule MbtaServer.Web.SessionControllerTest do
  use MbtaServer.Web.ConnCase
  alias MbtaServer.{User, Repo}

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "GET /login", %{conn: conn} do
    conn = get(conn, "/login")
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
end
