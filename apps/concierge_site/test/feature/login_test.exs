defmodule ConciergeSite.LoginTest do
  use ConciergeSite.FeatureCase, async: true
  alias AlertProcessor.{Model.User, Repo}

  import Wallaby.Query, only: [css: 2, text_field: 1, button: 1]

  @email "test@example.com"
  @password "password1"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "viewing the login page", %{session: session} do
    session
    |> visit("/")
    |> assert_has(css(".login-header", text: "Transportation alerts when you need them"))
  end

  test "logging in with an existing account", %{session: session} do
    Repo.insert!(%User{email: @email,
                       role: "user",
                       encrypted_password: @encrypted_password})

    session
    |> visit("/")
    |> fill_in(text_field("Email Address"), with: @email)
    |> fill_in(text_field("Password"), with: @password)
    |> click(button("Sign In"))
    |> assert_has(css(".header-link", text: "My Account"))
  end

  test "logging in with incorrect information", %{session: session} do
    Repo.insert!(%User{email: @email,
                       role: "user",
                       encrypted_password: @encrypted_password})

    session
    |> visit("/")
    |> fill_in(text_field("Email Address"), with: @email)
    |> fill_in(text_field("Password"), with: "wrong password")
    |> click(button("Sign In"))
    |> refute_has(css(".header-link", text: "My Account"))
    |> assert_has(css(".error-block", text: "Sorry, your login information was incorrect. Please try again."))
  end

  test "creating an account", %{session: session} do
    session
    |> visit("/")
    |> click(css("a", text: "Create one"))
    |> click(css("a", text: "Get Started"))
    |> fill_in(text_field("Email Address"), with: @email)
    |> fill_in(text_field("New password"), with: @password)
    |> fill_in(text_field("Re-enter new password"), with: @password)
    |> click(button("Create Account"))
    |> assert_has(css(".header-link", text: "My Account"))
  end
end
