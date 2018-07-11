defmodule ConciergeSite.Dissemination.DeliverLaterStrategyTest do
  use ExUnit.Case
  alias ConciergeSite.Dissemination.DeliverLaterStrategy
  alias ConciergeSite.Dissemination.DeliverLaterStrategyTest.{MockSuccessAdapter, MockSMTPErrorAdapter, MockRuntimeErrorAdapter}
  alias Bamboo.SMTPAdapter.SMTPError

  @moduletag :capture_log

  describe "deliver_later/3" do
    test "delivers email" do
      task = DeliverLaterStrategy.deliver_later(MockSuccessAdapter, "Mock email", %{})
      ref = Process.monitor(task.pid)

      assert_receive {:DOWN, ^ref, :process, _pid, :normal}, 1
    end

    test "handles SMTPError" do
      task = DeliverLaterStrategy.deliver_later(MockSMTPErrorAdapter, %{to: "Mock email address"}, %{})
      ref = Process.monitor(task.pid)

      assert_receive {:DOWN, ^ref, :process, _pid, :normal}, 100
    end

    test "handles unexpected errors" do
      task = DeliverLaterStrategy.deliver_later(MockRuntimeErrorAdaptertimeErrorAdapter, %{to: "Mock email address"}, %{})
      ref = Process.monitor(task.pid)

      assert_receive {:DOWN, ^ref, :process, _pid, :normal}, 100
    end
  end

  defmodule MockSuccessAdapter do
    def deliver(_email, _config), do: nil
  end

  defmodule MockSMTPErrorAdapter do
    def deliver(_email, _config) do
      raise SMTPError, {"mock reason", "mock detail"}
    end
  end

  defmodule MockRuntimeErrorAdapter do
    def deliver(_email, _config) do
      raise "mock runtime error"
    end
  end
end
