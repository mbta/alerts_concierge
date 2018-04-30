defmodule AlertProcessor.Dissemination.MailerTest do
  use ExUnit.Case
  alias AlertProcessor.Dissemination.Mailer

  @lookup_tuple {:via, Registry, {:mailer_process_registry, :fake_mailer}}

  setup_all do
    GenServer.start_link(AlertProcessor.Dissemination.ResponseServer, [], [name: @lookup_tuple])

    :ok
  end

  test "send_notification_email can call interface using via tuple" do
    {:ok, msg} = Mailer.send_notification_email(:fake_mailer, :fake_notification)
    assert {:send_notification_email, :fake_notification} = msg
  end
end

defmodule AlertProcessor.Dissemination.ResponseServer do
  use GenServer

  def init(args) do
    {:ok, args}
  end

  def handle_call(msg, _from, state) do
    {:reply, {:ok, msg}, state}
  end
end
