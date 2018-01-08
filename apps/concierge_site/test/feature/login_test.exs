defmodule ConciergeSite.LoginTest do
  use ConciergeSite.FeatureCase, async: true
  alias AlertProcessor.{Model.User, Repo}

  import ConciergeSite.FeatureTestHelper
  import Wallaby.Query, only: [css: 2, text_field: 1, button: 1]

  @email "test@example.com"
  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "viewing the login page", %{session: session} do
    session
    |> visit("/")
    |> assert_has(css(".login-header", text: "Welcome to T-Alerts Beta"))
  end

  test "loggin in with an existing account and logging out", %{session: session} do
    Repo.insert!(%User{email: @email,
                       role: "user",
                       encrypted_password: @encrypted_password})

    session
    |> visit("/")
    |> log_in(@email, @password)
    |> assert_has(css(".btn-link", text: "My Account"))
    |> assert_has(css(".log-out-link", count: 1))
    |> click(css(".log-out-link", count: 1))
    |> assert_has(css(".log-in-link", count: 1))
  end

  test "logging in with incorrect information", %{session: session} do
    Repo.insert!(%User{email: @email,
                       role: "user",
                       encrypted_password: @encrypted_password})

    session
    |> visit("/")
    |> log_in(@email, "wrong password")
    |> refute_has(css(".btn-link", text: "My Account"))
    |> assert_has(css(".error-block", text: "Sorry, your login information was incorrect. Please try again."))
  end

  test "creating an account", %{session: session} do
    session
    |> visit("/")
    |> click(css("a", text: "Create a T-Alerts account"))
    |> click(css("a", text: "Get Started"))
    |> fill_in(text_field("Email address"), with: @email)
    |> fill_in(text_field("New password"), with: @password)
    |> fill_in(text_field("Re-enter password"), with: @password)
    |> click(button("Create Account"))
    |> assert_has(css(".btn-link", text: "My Account"))
  end
end
