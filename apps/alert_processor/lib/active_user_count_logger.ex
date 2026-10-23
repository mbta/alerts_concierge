defmodule AlertProcessor.ActiveUserCountLogger do
  @moduledoc """
  Periodically logs the number of users with non-paused subscriptions.
  """

  use GenServer

  import Ecto.Query

  require Logger

  alias AlertProcessor.Repo
  alias AlertProcessor.Model.Subscription

  # Client

  @spec start_link() :: GenServer.on_start()
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  # Server

  @impl GenServer
  def init(_opts) do
    send(self(), :log_active_user_count)
    {:ok, nil}
  end

  @impl GenServer
  def handle_info(:log_active_user_count, state) do
    log_active_user_count()
    Process.send_after(self(), :log_active_user_count, :timer.hours(1))
    {:noreply, state, :hibernate}
  end

  defp log_active_user_count do
    active_users_by_communication_mode =
      Repo.all(
        from(s in Subscription,
          join: u in assoc(s, :user),
          where: not s.paused and u.communication_mode != "none",
          group_by: u.communication_mode,
          select: {u.communication_mode, count(u.id, :distinct)}
        )
      )
      |> Map.new()

    email_users = Map.get(active_users_by_communication_mode, "email", 0)
    sms_users = Map.get(active_users_by_communication_mode, "sms", 0)

    Logger.info("ActiveUserCountLogger email=#{email_users} sms=#{sms_users}")
  end
end
