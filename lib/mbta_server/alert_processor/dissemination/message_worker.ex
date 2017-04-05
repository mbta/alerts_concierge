defmodule MbtaServer.AlertProcessor.MessageWorker do
  @moduledoc """
  Worker process for processing a single AlertMessage from SendingQueue
  """
  use GenServer
  alias MbtaServer.AlertProcessor.{SendingQueue, Messager, Model.AlertMessage}
  @type message :: %AlertMessage{}
  @type messages :: list

  @doc false
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], [])
  end

  @doc false
  def init(state) do
    Process.send_after(self(), :message, 10)
    {:ok, state}
  end

  @doc """
  Checks sending queue for alert and sends it out to user
  """
  @spec handle_info(atom, messages) :: {:noreply, messages}
  def handle_info(:message, _state) do
    message = SendingQueue.pop
    case message do
      %AlertMessage{} ->
        Messager.send_alert_message(message)
        send(self(), :message)
      _ ->
        Process.send_after(self(), :message, 100)
    end
    {:noreply, _state}
  end
end
