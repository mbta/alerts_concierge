defmodule ConciergeSite.SessionControllerTest do
  use ConciergeSite.ConnCase
  alias AlertProcessor.{Model.User, Repo}

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)
  @disabled_password ""

  test "GET /login", %{conn: conn} do
    conn = get(conn, "/login/new")
    assert html_response(conn, 200) =~ "Welcome to T-Alerts Beta"
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

  test "POST /login when the user is an admin can access admin tools", %{conn: conn} do
    user = Repo.insert!(%User{email: "test@email.com",
                              role: "customer_support",
                              encrypted_password: @encrypted_password})

    params = %{"user" => %{
      "email" => user.email,
      "password" => @password
    }}

    conn = post(conn, "/login", params)
    assert html_response(conn, 302) =~ "/my-subscriptions"
  end

  test "POST /login when the user's account is disabled", %{conn: conn} do
    user = Repo.insert!(%User{email: "test@email.com",
                              role: "user",
                              encrypted_password: @disabled_password})

    params = %{"user" => %{
      "email" => user.email,
      "password" => @password
    }}

    conn = post(conn, "/login", params)
    assert html_response(conn, 302) =~ "/reset-password/new"
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
