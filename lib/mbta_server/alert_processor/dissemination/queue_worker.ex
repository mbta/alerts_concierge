defmodule MbtaServer.AlertProcessor.QueueWorker do
  @moduledoc """
  Worker process for processing AlertMessages from HoldingQueue
  """
  use GenServer
  alias MbtaServer.AlertProcessor.{HoldingQueue, SendingQueue, Model.AlertMessage}
  @type messages :: [AlertMessage.t]

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
  Checks holding queue for any messages that are ready to send and
  passes them to the sending queue
  """
  def handle_info(:message, state) do
    case HoldingQueue.messages_to_send() do
      :error ->
        Process.send_after(self(), :message, 100)
      {:ok, messages} ->
        send_messages(messages)
        send(self(), :message)
    end
    {:noreply, state}
  end

  defp send_messages(messages) do
    Enum.each(messages, &SendingQueue.enqueue/1)
  end
end
