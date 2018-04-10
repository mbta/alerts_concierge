defmodule ConciergeSite.SessionControllerTest do
  use ConciergeSite.ConnCase
  alias AlertProcessor.{Model.User, Repo}

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

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
