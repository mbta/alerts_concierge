defmodule AlertProcessor.Reminders do
  @moduledoc """
  Responsible for scheduling reminders.
  """

  use GenServer
  alias __MODULE__
  alias AlertProcessor.Model.Alert

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @spec async_schedule_reminders([Alert.t()]) :: :ok
  def async_schedule_reminders(pid \\ __MODULE__, alerts) do
    GenServer.cast(pid, {:schedule_reminders, alerts})
  end

  @impl true
  def init(_) do
    {:ok, %{updated_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_cast({:schedule_reminders, alerts}, state) do
    difference = DateTime.diff(DateTime.utc_now(), state.updated_at, :millisecond)

    new_updated_at =
      if abs(difference) > :timer.minutes(5) do
        Reminders.Processor.process_alerts(alerts)
        DateTime.utc_now()
      else
        state.updated_at
      end

    {:noreply, Map.put(state, :updated_at, new_updated_at)}
  end
end
