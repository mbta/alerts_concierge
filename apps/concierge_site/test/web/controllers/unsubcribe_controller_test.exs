defmodule ConciergeSite.UnsubscribeControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.Model.{Subscription, User}
  alias AlertProcessor.Repo

  describe "update/2" do
    test "unsubscribes user from all subscriptions", %{conn: conn} do
      conn =
        conn
        |> Map.put(
          :secret_key_base,
          Application.fetch_env!(:concierge_site, ConciergeSite.Endpoint)
          |> Keyword.fetch!(:secret_key_base)
        )

      trip_details = %{
        relevant_days: [:monday],
        start_time: ~T[12:00:00],
        end_time: ~T[12:30:00]
      }

      trip = insert(:trip, trip_details)

      subscription_details_1 = %{
        relevant_days: [:monday],
        start_time: ~T[12:00:00],
        end_time: ~T[12:30:00],
        origin: "some-origin",
        destination: "some-destination",
        trip: trip,
        paused: false,
        user_id: trip.user.id
      }

      subscription_details_2 = %{
        relevant_days: [:monday],
        start_time: ~T[12:00:00],
        end_time: ~T[12:30:00],
        origin: "some-other-origin",
        destination: "some-other-destination",
        trip: trip,
        paused: false,
        user_id: trip.user.id
      }

      subscription_1 = insert(:subscription, subscription_details_1)
      subscription_2 = insert(:subscription, subscription_details_2)

      assert trip.user.communication_mode == "email"

      encrypted_user_id =
        Plug.Crypto.encrypt(conn.secret_key_base, conn.secret_key_base, trip.user.id)

      post(
        conn,
        unsubscribe_path(conn, :update, encrypted_user_id)
      )

      updated_subscription_1 = Repo.get!(Subscription, subscription_1.id)
      updated_subscription_2 = Repo.get!(Subscription, subscription_2.id)

      for updated_subscription <- [updated_subscription_1, updated_subscription_2] do
        assert updated_subscription.paused == true
      end

      updated_user = User.get(trip.user.id)
      assert updated_user.communication_mode == "none"
    end
  end
end
