defmodule ConciergeSite.CreateSubscriptionTest do
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
    |> visit("/account/new")
    |> fill_in(text_field("user_email"), with: "test@test.com")
    |> fill_in(text_field("user_password"), with: @password)
    |> click(button("Create my account"))
    |> assert_has(css("#main", text: "Customize my settings"))
  end

  test "account options", %{session: session, user: user} do
    session
    |> log_in(user)
    |> visit("/account/options")
    |> assert_has(css("#main", text: "Customize my settings"))
    |> click(button("Next"))
    |> assert_has(css("#main", text: "Personalize my subscription"))
  end

  test "new session", %{session: session, user: user} do
    session
    |> visit("/login/new")
    |> fill_in(text_field("user_email"), with: user.email)
    |> fill_in(text_field("user_password"), with: @password)
    |> click(button("Go to my account"))
    |> assert_has(css("#main", text: "Customize my settings"))
  end

  test "failed login", %{session: session, user: user} do
    session
    |> visit("/login/new")
    |> fill_in(text_field("user_email"), with: user.email)
    |> fill_in(text_field("user_password"), with: "Password1!")
    |> click(button("Go to my account"))
    |> assert_has(css("#main", text: "Sorry, your login information was incorrect"))
  end

  test "trip index", %{session: session, user: user} do
    session
    |> log_in(user)
    |> visit("/trips")
    |> assert_has(css("#main", text: "My subscriptions"))
  end

  test "edit trip", %{session: session, user: user} do
    trip = insert(:trip, %{user: user})

    insert(:subscription, %{
      trip_id: trip.id,
      type: :cr,
      origin: "Readville",
      destination: "Newmarket",
      route: "CR-Fairmount"
    })

    session
    |> log_in(user)
    |> visit("/trips/#{trip.id}/edit")
    |> assert_has(css("#main", text: "Edit subscription"))
  end
end
