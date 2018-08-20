defmodule AlertProcessor.TripAuthorizerTest do
  use AlertProcessor.DataCase, async: true
  import AlertProcessor.Factory
  alias AlertProcessor.Authorizer.TripAuthorizer
  alias AlertProcessor.Model.Trip

  test "a user is authorized to act on a trip if the trip belongs to that user" do
    user_that_owns_trip = insert(:user)
    user_that_does_not_own_trip = insert(:user)

    trip =
      Repo.insert!(%Trip{
        user_id: user_that_owns_trip.id,
        alert_priority_type: :low,
        relevant_days: [:monday],
        start_time: ~T[12:00:00],
        end_time: ~T[18:00:00]
      })

    assert {:ok, :authorized} == TripAuthorizer.authorize(trip, user_that_owns_trip)
    assert {:error, :unauthorized} == TripAuthorizer.authorize(trip, user_that_does_not_own_trip)
  end
end
