defmodule ConciergeSite.EditSubscriptionTest do
  use ConciergeSite.FeatureCase, async: true

  import AlertProcessor.Factory
  import ConciergeSite.FeatureTestHelper
  import Wallaby.Query, only: [css: 2, checkbox: 1, text_field: 1, button: 1, link: 1]

  @password "p@ssw0rd"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "editing an accessibility subscription", %{session: session} do
    user = insert(:user, password: @password, encrypted_password: @encrypted_password)

    session
    |> log_in(user)
    |> create_subscription
    |> assert_has(css(".subscription-amenity-schedule", text: "1 station on Weekdays"))
    |> click(link("Accessibility Features"))
    |> click(checkbox("Weekdays"))
    |> click(checkbox("Sunday"))
    |> click(button("Update alert"))
    |> assert_has(css(".subscription-amenity-schedule", text: "1 station on Sundays"))
  end

  test "deleting a subscription", %{session: session} do
    user = insert(:user, password: @password, encrypted_password: @encrypted_password)

    session
    |> log_in(user)
    |> create_subscription("Weekdays")
    |> click(link("Create a new alert"))
    |> create_subscription("Sunday") # create two subscriptions so we go back to the index page after deletion
    |> click(link("1 station on Weekdays"))
    |> click(link("Delete Alert"))
    |> click(button("Yes, delete this alert"))
    |> assert_has(css(".alert-success", text: "Alert deleted"))
    |> refute_has(css(".subscription-amenity-schedule", text: "1 station on Weekdays"))
    |> assert_has(css(".subscription-amenity-schedule", text: "1 station on Sundays"))
  end

  defp create_subscription(session, days \\ "Weekdays") do
    session
    |> click(css("a", text: "Elevators and Accessibility"))
    |> click(checkbox("Elevators and ramps"))
    |> fill_in(text_field("station"), with: "Central")
    |> click(checkbox(days))
    |> click(button("Create alert"))
  end
end
