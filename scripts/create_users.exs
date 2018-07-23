defmodule CreateUsers do
  @moduledoc """
  Script to create users with subscriptions.

  Each user has an email address of the form:
    /send-alerts-test-\\d+@example.com/
    (example: send-alerts-test-55@example.com)

  The subscriptions are one-way subscriptions from Alewife to Downtown Crossing.
  The time period is 3:00-2:45 and it includes weekdays and weekends.

  Usage: mix run create_users.exs [options]
      -h, --help                       Print this message
      -c, --count                      Number of users to create
      -d, --delete                     Delete users previously created by script
  """

  @user_fields ~w(email phone_number encrypted_password)a

  def run(:help) do
    IO.write(@moduledoc)
  end

  def run({:create, count}) do
    create_users(count)
  end

  def run({:create_delete, count}) do
    run({:create, count})
    run(:delete)
  end

  def run(:delete) do
    delete()
  end

  def run(:exit) do
    run(:help)
    System.halt(1)
  end

  defp create_users(count, index \\ 0) do
    index
    |> Stream.iterate(&(&1 + 1))
    |> Stream.map(&create_user/1)
    |> Stream.map(&create_subscription/1)
    |> Enum.take(count)
  end

  defp create_user(count) do
    params = %{
      email: "send-alerts-test-#{count}@example.com",
      phone_number: "5555555555",
      # p@ssw0rd
      encrypted_password: "$2b$12$BwbCgTrrnXytfn733NZvV.RkLpMyO8Ga/zON5mSZAFz4/50kYYDhK"
    }

    %AlertProcessor.Model.User{}
    |> Ecto.Changeset.cast(params, @user_fields)
    |> PaperTrail.insert()
    |> normalize_papertrail_result
  end

  defp normalize_papertrail_result({:ok, %{model: user}}), do: user

  defp create_subscription(%{id: id} = user) do
    {:ok, subscription_infos} =
      %{
        "alert_priority_type" => "medium",
        "departure_end" => "02:45:00",
        "departure_start" => "03:00:00",
        "destination" => "place-dwnxg",
        "origin" => "place-alfcl",
        "route_type" => "1",
        "saturday" => "true",
        "sunday" => "true",
        "trip_type" => "one_way",
        "weekday" => "true"
      }
      |> Map.put("user_id", id)
      |> ConciergeSite.Subscriptions.SubwayParams.prepare_for_mapper()
      |> AlertProcessor.Subscription.SubwayMapper.map_subscriptions()

    subscription_infos
    |> AlertProcessor.Subscription.SubwayMapper.build_subscription_transaction(user, id)
    |> AlertProcessor.Model.Subscription.set_versioned_subscription()
  end

  defp delete do
    Ecto.Adapters.SQL.query!(
      AlertProcessor.Repo,
      "DELETE FROM notifications WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'send-alerts-test%')",
      [],
      timeout: :infinity
    )

    Ecto.Adapters.SQL.query!(
      AlertProcessor.Repo,
      "DELETE FROM versions WHERE originator_id IN (SELECT id FROM users WHERE email LIKE 'send-alerts-test%')",
      [],
      timeout: :infinity
    )

    Ecto.Adapters.SQL.query!(
      AlertProcessor.Repo,
      "DELETE FROM versions WHERE item_id IN (SELECT id FROM users WHERE email LIKE 'send-alerts-test%')",
      [],
      timeout: :infinity
    )

    Ecto.Adapters.SQL.query!(
      AlertProcessor.Repo,
      "DELETE FROM subscriptions WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'send-alerts-test%')",
      [],
      timeout: :infinity
    )

    Ecto.Adapters.SQL.query!(
      AlertProcessor.Repo,
      "DELETE FROM users WHERE id IN (SELECT id FROM users WHERE email LIKE 'send-alerts-test%')",
      [],
      timeout: :infinity
    )
  end
end

opts =
  OptionParser.parse(
    System.argv(),
    switches: [help: :boolean, count: :integer, delete: :boolean],
    aliases: [h: :help, c: :count, d: :delete]
  )

case opts do
  {[help: true], _, _} -> :help
  {[count: n, delete: true], _, _} -> {:create_delete, n}
  {[count: n], _, _} -> {:create, n}
  {[delete: true], _, _} -> :delete
  _ -> :exit
end
|> CreateUsers.run()
