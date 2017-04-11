defmodule MbtaServer.AlertProcessor.MessageWorker do
  @moduledoc """
  Worker process for processing a single AlertMessage from SendingQueue
  """
  use GenServer
  alias MbtaServer.AlertProcessor.{SendingQueue, Messager, Model.AlertMessage}
  @type messages :: [AlertMessage.t]

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
  def handle_info(:message, state) do
    case SendingQueue.pop do
      {:ok, %AlertMessage{} = message} ->
        Messager.send_alert_message(message)
        send(self(), :message)
      :error ->
        Process.send_after(self(), :message, 100)
    end
    {:noreply, state}
  end
  def handle_info(_, state) do
    {:noreply, state}
  end
end
