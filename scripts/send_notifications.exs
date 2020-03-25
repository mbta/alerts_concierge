defmodule SendNotifications do
  @moduledoc """
  Script to enqueue a number of fake notifications for testing purposes.

  All notifications are via SMS to the number 555-555-5555, and are considered to be "for" the
  user with email address `send-alerts-test-notifications@example.com`. This user will be created
  if it doesn't already exist.

  The script does not exit until all notifications have been removed from the queue.

  Usage: mix run send_notifications.exs [options]
      -h, --help                       Print this message
      -c, --count                      Number of notifications to send
  """

  alias AlertProcessor.Model.{User, Notification}
  alias AlertProcessor.{Repo, SendingQueue}

  @user_email "send-alerts-test-notifications@example.com"

  def run(:help) do
    IO.write(@moduledoc)
  end

  def run({:create, count}) do
    schedule_notifications(count)
    await_notifications_sent()
  end

  def run(:exit) do
    run(:help)
    System.halt(1)
  end

  defp schedule_notifications(count, index \\ 0) do
    datetime = DateTime.utc_now()
    user = find_or_create_user()

    index
    |> Stream.iterate(&(&1 + 1))
    |> Stream.map(&notification(&1, datetime, user))
    |> Stream.map(&SendingQueue.enqueue/1)
    |> Enum.take(count)
  end

  defp await_notifications_sent do
    {:ok, length} = SendingQueue.queue_length()

    if length > 0 do
      :timer.sleep(100)
      await_notifications_sent()
    end
  end

  defp notification(count, datetime, user) do
    %Notification{
      alert_id: "alert-#{count}",
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
    case Repo.get_by(User, email: @user_email) do
      %User{} = user ->
        user

      _ ->
        params = %{"email" => @user_email, "password" => "Password1"}

        {:ok, user} = User.create_account(params)
        user
    end
  end
end

opts =
  OptionParser.parse(
    System.argv(),
    switches: [help: :boolean, count: :integer],
    aliases: [h: :help, c: :count]
  )

case opts do
  {[help: true], _, _} -> :help
  {[count: n], _, _} -> {:create, n}
  _ -> :exit
end
|> SendNotifications.run()
