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
    active_user_ids =
      from(s in Subscription, where: not s.paused, distinct: true, select: s.user_id)

    active_users = Repo.aggregate(active_user_ids, :count)
    Logger.info("ActiveUserCountLogger active_user_count=#{active_users}")
  end
end
