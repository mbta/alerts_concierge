defmodule ConciergeSite.ParkingSubscriptionTest do
  use ConciergeSite.FeatureCase, async: true

  import AlertProcessor.Factory
  import ConciergeSite.FeatureTestHelper
  import Wallaby.Query, only: [css: 2, checkbox: 1, text_field: 1, button: 1]

  @password "p@ssw0rd"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "creating a parking subscription", %{session: session} do
    user = insert(:user, password: @password, encrypted_password: @encrypted_password)

    session
    |> log_in(user)
    |> click(css("a", text: "Parking"))
    |> fill_in(text_field("station"), with: "South Station")
    |> click(checkbox("Weekdays"))
    |> click(button("Create Subscription"))
    |> assert_has(css(".header-text", text: "My Subscriptions"))
    |> assert_has(css(".subscription-route", text: "Parking"))
  end
end
