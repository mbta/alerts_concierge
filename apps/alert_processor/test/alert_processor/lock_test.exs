defmodule AlertProcessor.LockTest do
  use ExUnit.Case

  alias AlertProcessor.Lock

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(AlertProcessor.Repo, :auto)
  end

  describe "acquire/1" do
    test "calls the function with :ok if the lock is acquired" do
      # assert sequential calls can acquire the lock
      assert Lock.acquire(fn :ok -> true end)
      assert Lock.acquire(fn :ok -> true end)
    end

    test "calls the function with :error if the lock is already acquired" do
      acquire_and_sleep(&spawn_link/1)

      assert Lock.acquire(fn :error -> true end)
    end

    defmodule TestError do
      defexception [:message]
    end

    test "releases the lock if the function raises an exception" do
      try do
        Lock.acquire(fn :ok -> raise TestError end)
      rescue
        TestError -> nil
      end

      assert Lock.acquire(fn :ok -> true end)
    end

    test "releases the lock if the calling process dies" do
      pid = acquire_and_sleep(&spawn/1)
      Process.monitor(pid)

      Process.exit(pid, :test_reason)
      assert_receive {:DOWN, _, _, ^pid, :test_reason}

      assert Lock.acquire(fn :ok -> true end)
    end

    defp acquire_and_sleep(spawn_fn) do
      test_pid = self()

      # Spawn a process that acquires the lock and sits on it forever
      pid =
        spawn_fn.(fn ->
          Lock.acquire(fn :ok ->
            send(test_pid, :acquired)
            Process.sleep(:infinity)
          end)
        end)

      # Wait for the spawned process to get the lock before proceeding
      receive do
        :acquired -> pid
      end
    end
  end
end
