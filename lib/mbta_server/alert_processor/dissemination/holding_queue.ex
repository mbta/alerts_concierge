defmodule MbtaServer.AlertProcessor.HoldingQueue do
  @moduledoc """
  Parent service to handle queuing of incoming alerts
  """
  use GenServer
  alias MbtaServer.AlertProcessor.{SendingQueue, Model}
  alias Model.AlertMessage

  @filter_interval Application.get_env(:mbta_server, __MODULE__)[:filter_interval]

  @type alert :: %AlertMessage{}
  
  @doc false
  def start_link do
    GenServer.start_link(__MODULE__, :queue.new(), [name: __MODULE__])
  end

  @doc false
  def start_link(alerts) do
    GenServer.start_link(__MODULE__, :queue.from_list(alerts), [name: __MODULE__])
  end

  defp filter_queue(queue) do
    now = DateTime.utc_now()
    :queue.filter(fn(alert) -> send_alert?(alert, now) end, queue)
    |> make_list
    |> Enum.each(fn(alert) -> 
      SendingQueue.enqueue(alert)
    end)

    :queue.filter(fn(alert) -> !send_alert?(alert, now) end, queue)
  end

  defp make_list({h, t}) do
    h ++ t
  end

  defp send_alert?(alert, now) do
    case DateTime.compare(Map.get(alert, :send_after), now) do
      :gt -> false
      _ -> true
    end
  end

  @doc """
  Add alert to holding queue or add to sending queue as appropriate based on date
  """
  @spec enqueue(alert) :: {atom, atom}
  def enqueue(alert) do
    case send_alert?(alert, DateTime.utc_now()) do
      true -> 
        SendingQueue.enqueue([alert])
      false -> 
        GenServer.call(__MODULE__, {:push, alert})
    end
  end

  ## Callbacks

  @doc """
  Schedule recurring check of queue
  """
  def init(state) do
    send(self(), :schedule)
    {:ok, state}
  end

  @doc """
  Check queue for any alerts that can be moved, then schedule another check
  """
  def handle_info(:schedule, queue) do
    state = filter_queue(queue)
    Process.send_after(self(), :schedule, @filter_interval)
    {:noreply, state}
  end

  @doc """
  Add alert to queue
  """
  def handle_call({:push, alert}, _from, queue) do
    newstate = :queue.in(alert, queue)
    {:reply, :success, newstate}
  end

  @doc false
  def handle_call(request, from, state) do
    super(request, from, state)
  end
end
