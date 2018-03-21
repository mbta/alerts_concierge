defmodule AlertProcessor.Model.Subscription.SyncWithTrip do
  @moduledoc """
  Syncs a subscription with a given trip's attributes.
  """

  alias AlertProcessor.Repo
  alias AlertProcessor.Model.{User, Trip, Subscription}

  @doc """
  Syncs the following subscription fields based on a given trip's attributes:

  * `relevant_days`
  * `start_time`
  * `end_time`
  """
  @spec perform(Subscription.t, Trip.t) :: {:ok, Subscription.t} :: {:error, Ecto.Changeset.t}
  def perform(%Subscription{} = subscription, %Trip{} = trip) do
    params = %{
      relevant_days: trip.relevant_days,
      start_time: start_time(trip, subscription),
      end_time: end_time(trip, subscription),
    }
    user = Repo.get!(User, trip.user_id)
    Subscription.update_subscription(subscription, params, user)
  end

  defp start_time(%Trip{} = trip, %Subscription{return_trip: false}) do
    trip.start_time
  end

  defp start_time(%Trip{} = trip, %Subscription{return_trip: true}) do
    trip.return_start_time
  end

  defp end_time(%Trip{} = trip, %Subscription{return_trip: false}) do
    trip.end_time
  end

  defp end_time(%Trip{} = trip, %Subscription{return_trip: true}) do
    trip.return_end_time
  end
end
