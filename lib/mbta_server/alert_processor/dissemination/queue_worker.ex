defmodule MbtaServer.AlertProcessor.QueueWorker do
  @moduledoc """
  Worker process for processing AlertMessages from HoldingQueue
  """
  use GenServer
  alias MbtaServer.AlertProcessor.{HoldingQueue, SendingQueue, Model.AlertMessage}
  @type message :: AlertMessage.t
  @type messages :: List.t

  @doc false
  def start_link() do
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
  def handle_info(:message, state) do
    case HoldingQueue.messages_to_send() do
      {:error, :empty} ->
        Process.send_after(self(), :message, 100)
      {:success, messages} ->
        send_messages(messages)
        send(self(), :message)
    end
    {:noreply, state}
  end

  defp send_messages(messages) do
    messages
    |> Enum.each(fn(message) -> SendingQueue.enqueue(message) end)
  end
end
