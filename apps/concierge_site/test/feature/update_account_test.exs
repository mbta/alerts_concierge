defmodule ConciergeSite.UpdateAccountTest do
  use ConciergeSite.FeatureCase, async: true

  import AlertProcessor.Factory
  import ConciergeSite.FeatureTestHelper
  import Wallaby.Query, only: [css: 2, radio_button: 1, text_field: 1, button: 1, link: 1]

  @password "p@ssw0rd"
  @encrypted_password Comeonin.Bcrypt.hashpwsalt(@password)

  test "switching to a text subscription", %{session: session} do
    user = insert(:user, password: @password, encrypted_password: @encrypted_password)

    session
    |> log_in(user)
    |> click(link("Menu"))
    |> click(link("My Account"))
    |> click(radio_button("Yes - only send me text alerts"))
    |> fill_in(text_field("Phone Number"), with: "5554443333")
    |> click(button("Update account preferences"))
    |> assert_has(css(".header-container", text: "Create a new alert"))
    |> click(link("Menu"))
    |> click(link("My Account"))
    |> assert_has(css("#user_phone_number", value: "5554443333"))
  end
end
