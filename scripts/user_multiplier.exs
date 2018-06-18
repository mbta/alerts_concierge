defmodule UserMultiplier do
  @moduledoc """
  Responsible for duplicating existing users, trips, and subscriptions for load
  testing. 

  To create 1,000 new users:

  ```
  mix run ./scripts/user_multiplier --count 1000
  ```

  This will create 1,000 new users based on the data of existing users in the
  DB. For each new user, it first gets a random user from the DB (with it's
  trips and subscriptions), and then duplicates it.

  """

  use Mix.Task
  import Ecto.Query
  alias AlertProcessor.Repo
  alias AlertProcessor.Model.User

  def run({:create, count}), do: create_new_users(count)

  def run(:exit), do: System.halt(1)

  def create_new_users(count) do
    for index <- 1..count do
      IO.puts "Creating new user: #{index}"

      user = random_user()
      trips = user.trips

      {:ok, inserted_user} =
        user
        |> prepare_user(index)
        |> Repo.insert()

      for trip <- trips do
        subscriptions = trip.subscriptions

        {:ok, inserted_trip} =
          trip
          |> prepare_trip(inserted_user)
          |> Repo.insert()

        for subscription <- subscriptions do
          subscription
          |> prepare_subscription(inserted_trip, inserted_user)
          |> Repo.insert()
        end
      end
    end
  end

  def random_user() do
    Repo.all(
      from u in User,
      join: t in assoc(u, :trips),
      join: s in assoc(t, :subscriptions),
      limit: 200,
      preload: [trips: :subscriptions],
      select: u
    )
    |> Enum.random()
  end

  def prepare_user(user, index) do
    user
    |> Map.delete(:id)
    |> Map.delete(:inserted_at)
    |> Map.delete(:subscription)
    |> Map.update(:trips, [], &(Enum.drop_every(&1, 1)))
    |> Map.update(:email, nil, &("Copy#{index}-#{:rand.uniform(10_000)}Of#{&1}"))
  end

  def prepare_trip(trip, user) do
    trip
    |> Map.delete(:id)
    |> Map.delete(:inserted_at)
    |> Map.update(:subscriptions, [], &(Enum.drop_every(&1, 1)))
    |> Map.delete(:user)
    |> Map.put(:user_id, user.id)
  end

  def prepare_subscription(subscription, trip, user) do
    subscription
    |> Map.delete(:id)
    |> Map.delete(:inserted_at)
    |> Map.put(:user_id, user.id)
    |> Map.delete(:user)
    |> Map.delete(:trip)
    |> Map.put(:trip_id, trip.id)
    |> Map.update(:informed_entities, [], &(Enum.drop_every(&1, 1)))
  end
end

opts = OptionParser.parse(System.argv(), switches: [count: :integer])

case opts do
  {[count: n], _, _} -> {:create, n}
  _ -> :exit
end
|> UserMultiplier.run()
