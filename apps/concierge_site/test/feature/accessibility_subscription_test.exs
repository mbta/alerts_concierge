defmodule ConciergeSite.AccessibilitySubscriptionTest do
  use ConciergeSite.FeatureCase, async: true

  import AlertProcessor.Factory
  import ConciergeSite.FeatureTestHelper
  import Wallaby.Query, only: [css: 2, checkbox: 1, text_field: 1, button: 1]

  @password "p@ssw0rd"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "creating an accessibility subscription", %{session: session} do
    user = insert(:user, password: @password, encrypted_password: @encrypted_password)

    session
    |> log_in(user)
    |> click(css("a", text: "Elevators and Accessibility"))
    |> click(checkbox("Elevators and ramps"))
    |> fill_in(text_field("station"), with: "Central")
    |> click(checkbox("Weekdays"))
    |> click(button("Create alert"))
    |> assert_has(css(".header-container", text: "My Subscriptions"))
    |> assert_has(css(".subscription-details", text: "Elevated subplatform, Elevator, and Portable boarding lift"))
  end
end
