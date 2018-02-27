defmodule ConciergeSite.V2.CreateSubscriptionTest do
  use ConciergeSite.FeatureCase, async: true

  import AlertProcessor.Factory
  import ConciergeSite.FeatureTestHelper
  import Wallaby.Query

  @password "p@ssw0rd"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  setup do
    user = insert(:user, password: @password, encrypted_password: @encrypted_password)
    {:ok, user: user}
  end

  test "new account", %{session: session} do
    session
    |> visit("/v2/account/new")
    |> fill_in(text_field("user_email"), with: "test@test.com")
    |> fill_in(text_field("user_password"), with: @password)
    |> click(button("Create my account"))
    |> assert_has(css("#main", text: "account options"))
  end

  test "account options", %{session: session, user: user} do
    session
    |> log_in(user)
    |> visit("/v2/account/options")
    |> assert_has(css("#main", text: "account options"))
  end

  test "new leg", %{session: session, user: user} do
    session
    |> log_in(user)
    |> visit("/v2/trip/leg/new")
    |> assert_has(css("#main", text: "new leg"))
  end

  test "home page", %{session: session} do
    session
    |> visit("/v2/")
    |> assert_has(css("#main", text: "Welcome to T-Alerts!"))
  end

  test "new session", %{session: session, user: user} do
    session
    |> visit("/v2/login/new")
    |> fill_in(text_field("user_email"), with: user.email)
    |> fill_in(text_field("user_password"), with: @password)
    |> click(button("Go to my account"))
    |> assert_has(css("#main", text: "account options"))
  end

  test "failed login", %{session: session, user: user} do
    session
    |> visit("/v2/login/new")
    |> fill_in(text_field("user_email"), with: user.email)
    |> fill_in(text_field("user_password"), with: "Password1!")
    |> click(button("Go to my account"))
    |> assert_has(css("#main", text: "Sorry, your login information was incorrect"))
  end

  test "trip index", %{session: session, user: user} do
    session
    |> log_in(user)
    |> visit("/v2/trips")
    |> assert_has(css("#main", text: "trip index"))
  end

  test "new trip", %{session: session, user: user} do
    session
    |> log_in(user)
    |> visit("/v2/trip/new")
    |> assert_has(css("#main", text: "new trip"))
  end

  test "edit trip", %{session: session, user: user} do
    session
    |> log_in(user)
    |> visit("/v2/trips/:id/edit")
    |> assert_has(css("#main", text: "edit trip"))
  end

  test "trip times", %{session: session, user: user} do
    session
    |> log_in(user)
    |> visit("/v2/trip/times")
    |> assert_has(css("#main", text: "new trip times"))
  end

  test "trip accessibility", %{session: session, user: user} do
    session
    |> log_in(user)
    |> visit("/v2/trip/accessibility")
    |> assert_has(css("#main", text: "accessibility"))
  end
end
