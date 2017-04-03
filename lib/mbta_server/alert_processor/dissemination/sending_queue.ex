defmodule MbtaServer.AlertProcessor.SendingQueue do
  @moduledoc """
  Queue for holding alerts ready to be sent 
  """
  use GenServer
  alias MbtaServer.AlertProcessor.Model.AlertMessage

  @type alert :: %AlertMessage{}

  def start_link do
    GenServer.start_link(__MODULE__, :queue.new(), [name: __MODULE__])
  end

  def init(state) do
    {:ok, state}
  end

  @doc """
  Adds alert to qeue 
  """
  @spec enqueue(alert) :: {atom, atom} 
  def enqueue(alert) do
    case alert do
      %AlertMessage{} -> 
        GenServer.call(__MODULE__, {:push, alert}) 
      _ -> {:reply, :no_update} 
    end
  end

  @doc """
  Returns alert from queue
  """
  @spec pop() :: alert
  def pop do
    GenServer.call(__MODULE__, :pop) 
  end

  @doc false
  def handle_call(:pop, _from, queue) do
    {{:value, alert}, newstate} = :queue.out(queue)
    {:reply, alert, newstate}
  end

  @doc false
  def handle_call({:push, alert}, _from, queue) do
    newstate = :queue.in(alert, queue)
    {:reply, :success, newstate}
  end

  @doc false
  def handle_call(request, from, state) do
    super(request, from, state)
  end
end
