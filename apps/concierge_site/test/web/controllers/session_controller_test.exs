defmodule ConciergeSite.SessionControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.{Model.User, Model.Trip, Repo}

  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "GET /login/new", %{conn: conn} do
    conn = get(conn, session_path(conn, :new))
    assert html_response(conn, 200) =~ "Sign in"
  end

  test "POST /login", %{conn: conn} do
    user =
      Repo.insert!(%User{
        email: "test@email.com",
        role: "user",
        encrypted_password: @encrypted_password
      })

    params = %{"user" => %{"email" => user.email, "password" => @password}}
    conn = post(conn, session_path(conn, :create), params)
    assert html_response(conn, 302) =~ "/account/options"
  end

  test "POST /login with trips", %{conn: conn} do
    user =
      Repo.insert!(%User{
        email: "test@email.com",
        role: "user",
        encrypted_password: @encrypted_password
      })

    Repo.insert!(%Trip{
      user_id: user.id,
      relevant_days: [:monday],
      start_time: ~T[12:00:00],
      end_time: ~T[18:00:00],
      facility_types: [:elevator]
    })

    params = %{"user" => %{"email" => user.email, "password" => @password}}
    conn = post(conn, session_path(conn, :create), params)
    assert html_response(conn, 302) =~ "<a href=\"/trips\">"
  end

  test "POST /login rejected", %{conn: conn} do
    user =
      Repo.insert!(%User{
        email: "test@email.com",
        role: "user",
        encrypted_password: @encrypted_password
      })

    params = %{"user" => %{"email" => user.email, "password" => "11111111111"}}
    conn = post(conn, session_path(conn, :create), params)
    assert html_response(conn, 200) =~ "information was incorrect"
  end

  test "DELETE /login", %{conn: conn} do
    user = insert(:user)

    conn =
      user
      |> guardian_login(conn)
      |> delete(session_path(conn, :delete))

    assert redirected_to(conn, 302) =~ session_path(conn, :new)
  end

  test "unauthenticated/2", %{conn: conn} do
    # trip index path requires authentication so it is handled by
    # `unauthenticated/2` if user has not logged in
    conn = get(conn, trip_path(conn, :index))
    assert redirected_to(conn, 302) =~ session_path(conn, :new)
  end
end
