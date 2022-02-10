defmodule AlertProcessor.AlertWorkerTest do
  use AlertProcessor.DataCase
  alias AlertProcessor.{AlertWorker, AlertWorker.State}
  alias AlertProcessor.Lock
  alias AlertProcessor.Model.Metadata

  setup do
    # Required due to Lock using a spawned process
    Ecto.Adapters.SQL.Sandbox.mode(AlertProcessor.Repo, :auto)
    Metadata.delete(AlertWorker)
  end

  describe "server" do
    test "calls the alert processing function according to the frequencies" do
      test_pid = self()

      {:ok, worker} =
        AlertWorker.start_link(
          check_interval: 10,
          frequencies: %{recent: 1, older: 2},
          process_fn: fn type -> send(test_pid, type) end
        )

      try do
        # `recent` is listed first and both are equally stale
        assert_receive :recent
        # now `recent` has been done and `older` is more stale
        assert_receive :older
        # after ~1s both are equally stale again (in whole seconds)
        assert_receive :recent, 1000
      after
        GenServer.stop(worker)
      end
    end
  end

  describe "check" do
    defp handle_check(now, frequencies) do
      test_pid = self()

      AlertWorker.handle_info(:check, %State{
        check_interval: nil,
        frequencies: frequencies,
        now_fn: fn -> now end,
        process_fn: fn type -> send(test_pid, type) end
      })
    end

    test "processes the most stale duration type and updates the metadata" do
      Metadata.put(AlertWorker, %{
        last_processed_times: %{
          recent: DateTime.to_iso8601(~U[2021-01-01 11:59:52Z]),
          older: DateTime.to_iso8601(~U[2021-01-01 11:59:39Z]),
          oldest: DateTime.to_iso8601(~U[2021-01-01 11:59:32Z])
        }
      })

      handle_check(~U[2021-01-01 12:00:00Z], %{recent: 10, older: 20, oldest: 30})

      expected_meta = %{
        "recent" => "2021-01-01T11:59:52Z",
        "older" => "2021-01-01T12:00:00Z",
        "oldest" => "2021-01-01T11:59:32Z"
      }

      assert_receive :older
      assert AlertWorker |> Metadata.get() |> Map.get("last_processed_times") == expected_meta
    end

    test "treats a duration type as infinitely stale if it has no last-processed time" do
      Metadata.put(AlertWorker, %{
        last_processed_times: %{
          recent: DateTime.to_iso8601(~U[2021-01-01 11:59:49Z]),
          older: DateTime.to_iso8601(~U[2021-01-01 11:59:37Z])
        }
      })

      handle_check(~U[2021-01-01 12:00:00Z], %{recent: 10, older: 20, oldest: 30})

      assert_receive :oldest
      assert AlertWorker |> Metadata.get() |> get_in(["last_processed_times", "oldest"])
    end

    test "does not process any duration types if none are stale" do
      Metadata.put(AlertWorker, %{
        last_processed_times: %{
          recent: DateTime.to_iso8601(~U[2021-01-01 11:59:51Z]),
          older: DateTime.to_iso8601(~U[2021-01-01 11:59:41Z])
        }
      })

      handle_check(~U[2021-01-01 12:00:00Z], %{recent: 10, older: 20})

      refute_receive :recent
      refute_receive :older
    end

    test "does not process if the exclusive lock is already in use" do
      test_pid = self()

      # Acquire the lock and sit on it forever (or until the test exits)
      spawn_link(fn ->
        Lock.acquire(AlertWorker, fn :ok ->
          send(test_pid, :acquired)
          Process.sleep(:infinity)
        end)
      end)

      # Wait for above process to get the lock, otherwise the AlertWorker might get it first
      assert_receive :acquired

      handle_check(~U[2021-01-01 12:00:00Z], %{recent: 10})

      refute_receive :recent
    end
  end
end
