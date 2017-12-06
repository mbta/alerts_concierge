defmodule ConciergeSite.AccessibilitySubscriptionTest do
  use ConciergeSite.FeatureCase, async: true

  import AlertProcessor.Factory
  import Wallaby.Query, only: [css: 2, checkbox: 1, text_field: 1, button: 1]

  @password "p@ssw0rd"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "creating an accessibility subscription", %{session: session} do
    user = insert(:user, password: @password, encrypted_password: @encrypted_password)

    session
    |> log_in(user)
    |> click(css("a", text: "Elevators and Accessibility"))
    |> click(checkbox("Elevators and step-free access"))
    |> fill_in(text_field("station"), with: "Central")
    |> click(checkbox("Weekdays"))
    |> click(button("Create Subscription"))
    |> assert_has(css(".header-text", text: "My Subscriptions"))
    |> assert_has(css(".subscription-details", text: "Elevated subplatform, Portable boarding lift, and Elevator"))
  end

  test "creating a parking subscription", %{session: session} do
    user = insert(:user, password: @password, encrypted_password: @encrypted_password)

    session
    |> log_in(user)
    |> click(css("a", text: "Accessibility"))
    |> click(checkbox("Parking"))
    |> fill_in(text_field("station"), with: "South Station")
    |> click(checkbox("Weekdays"))
    |> click(button("Create Subscription"))
    |> assert_has(css(".header-text", text: "My Subscriptions"))
    |> assert_has(css(".subscription-details", text: "Parking area"))
  end

  test "creating a bike storage subscription", %{session: session} do
    user = insert(:user, password: @password, encrypted_password: @encrypted_password)

    session
    |> log_in(user)
    |> click(css("a", text: "Accessibility"))
    |> click(checkbox("Bike Storage"))
    |> fill_in(text_field("station"), with: "Alewife")
    |> click(checkbox("Weekdays"))
    |> click(button("Create Subscription"))
    |> assert_has(css(".header-text", text: "My Subscriptions"))
    |> assert_has(css(".subscription-details", text: "Bike storage"))
  end

  defp log_in(session, user) do
    session
    |> visit("/")
    |> fill_in(text_field("Email Address"), with: user.email)
    |> fill_in(text_field("Password"), with: user.password)
    |> click(button("Sign In"))
  end
end
