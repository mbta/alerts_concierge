defmodule SendNotifications do
  @moduledoc """
  Script to queue up and then dequeue a bunch of notifications

  Each notification belongs to a user with email address:
    send-alerts-test-notifications@example.com

  It sends text messages to the number 5555555555 and uses the AwsMock (at
  least when run in dev)

  Usage: env RATE_LIMIT=count mix run create_users.exs [options]
      -h, --help                       Print this message
      -c, --count                      Number of notifications to send
      -d, --delete                     Delete notifications previously created by script
  """

  alias AlertProcessor.Model.{User, Notification}
  alias AlertProcessor.Repo

  import Ecto.Query

  @user_email "send-alerts-test-notifications@example.com"

  def run(:help) do
    IO.write(@moduledoc)
  end
  def run({:create, count}) do
    create_send_and_wait(count)
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

  defp create_send_and_wait(count) do
    original_count = number_of_sent_notifications()

    schedule_notifications(count)

    check_sent_notifications(original_count, count)
  end

  defp delete do
    Ecto.Adapters.SQL.query!(AlertProcessor.Repo,
      "DELETE FROM notifications WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'send-alerts-test%')", [],
      [timeout: :infinity])
  end

  defp schedule_notifications(count, index \\ 0) do
    datetime = DateTime.utc_now()
    user = find_or_create_user()

    index
    |> Stream.iterate(& &1 + 1)
    |> Stream.map(& notification(&1, datetime, user))
    |> Stream.map(&AlertProcessor.HoldingQueue.enqueue/1)
    |> Enum.take(count)
  end

  defp check_sent_notifications(original_count, count) do
    current_count = number_of_sent_notifications()
    if current_count - original_count < count do
      :timer.sleep(100)
      check_sent_notifications(original_count, count)
    end
  end

  defp number_of_sent_notifications do
    Repo.one(from n in Notification, select: count("*"))
  end

  defp notification(count, datetime, user) do
    %Notification{alert_id: "alert-#{count}",
      user_id: user.id,
      user: user,
      send_after: datetime,
      service_effect: "Delay",
      header: "There's a delay",
      email: @user_email,
      phone_number: "5555555555"
    }
  end

  defp find_or_create_user do
    case AlertProcessor.Repo.get_by(User, email: @user_email) do
      %User{} = user -> user
      _ ->
        params = %{"email" => @user_email, "password" => "Password1"}

        {:ok, user} = User.create_account(params)
        user
    end
  end
end

opts = OptionParser.parse(System.argv(),
  switches: [help: :boolean , count: :integer, delete: :boolean],
  aliases: [h: :help, c: :count, d: :delete])

case opts do
  {[help: true], _, _} -> :help
  {[count: n, delete: true], _, _} -> {:create_delete, n}
  {[count: n], _, _} -> {:create, n}
  {[delete: true], _, _} -> :delete
  _ -> :exit
end
|> SendNotifications.run()
