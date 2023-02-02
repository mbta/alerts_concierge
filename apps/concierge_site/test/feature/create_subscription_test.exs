defmodule ConciergeSite.CreateSubscriptionTest do
  @moduledoc false
  use ConciergeSite.FeatureCase

  import AlertProcessor.Factory
  import Test.Support.Helpers
  import Wallaby.Query, only: [text_field: 1, button: 1, css: 2]

  @password "p@ssw0rd"
  @encrypted_password Bcrypt.hash_pwd_salt(@password)

  setup do
    Application.put_env(:wallaby, :base_url, ConciergeSite.Endpoint.url())
    reassign_env(:concierge_site, ConciergeSite.Endpoint, authentication_source: "local")
    user = insert(:user, password: @password, encrypted_password: @encrypted_password)
    {:ok, user: user}
  end

  feature "new account", %{session: session} do
    session
    |> visit("/account/new")
    |> fill_in(text_field("user_email"), with: "test@test.com")
    |> fill_in(text_field("user_password"), with: @password)
    |> click(button("Create my account"))
    |> assert_has(css("#main", text: "Customize my settings"))
  end

  feature "account options", %{session: session, user: user} do
    session
    |> log_in(user)
    |> visit("/account/options")
    |> assert_has(css("#main", text: "Customize my settings"))
    |> click(button("Next"))
    |> assert_has(css("#main", text: "Personalize my subscription"))
  end

  feature "new session", %{session: session, user: user} do
    session
    |> visit("/login/new")
    |> fill_in(text_field("user_email"), with: user.email)
    |> fill_in(text_field("user_password"), with: @password)
    |> click(button("Go to my account"))
    |> assert_has(css("#main", text: "Customize my settings"))
  end

  feature "failed login", %{session: session, user: user} do
    session
    |> visit("/login/new")
    |> fill_in(text_field("user_email"), with: user.email)
    |> fill_in(text_field("user_password"), with: "Password1!")
    |> click(button("Go to my account"))
    |> assert_has(css("#main", text: "Sorry, your login information was incorrect"))
  end

  feature "trip index", %{session: session, user: user} do
    session
    |> log_in(user)
    |> visit("/trips")
    |> assert_has(css("#main", text: "My subscriptions"))
  end

  feature "edit trip", %{session: session, user: user} do
    trip = insert(:trip, %{user: user})

    insert(:subscription, %{
      trip_id: trip.id,
      type: :cr,
      origin: "place-DB-0095",
      destination: "place-DB-2265",
      route: "CR-Fairmount"
    })

    session
    |> log_in(user)
    |> visit("/trips/#{trip.id}/edit")
    |> assert_has(css("#main", text: "Edit subscription"))
  end
end
