defmodule AlertProcessor.Lock do
  @moduledoc "Provides a database-backed exclusive lock."
  alias AlertProcessor.Repo

  # Mapping of known modules to keys.
  @keys %{
    AlertProcessor.AlertWorker => 0,
    AlertProcessor.SmsOptOutWorker => 1
  }

  @doc """
  Tries to acquire an exclusive advisory lock using the `AlertProcessor.Repo` database. The lock
  can be identified by a "known" atom, which is mapped to a key, or by specifying a key directly.
  The passed function is called with `:ok` if the lock was acquired, or `:error` if it was not.

  Returns whatever the passed function returns.
  """
  @spec acquire(atom | non_neg_integer, (:ok | :error -> any)) :: any

  def acquire(key, func) when is_atom(key) do
    @keys |> Map.fetch!(key) |> acquire(func)
  end

  def acquire(key, func) when is_integer(key) do
    # We want to allow multiple transactions to occur "within" a lock. It might appear the best
    # way to handle this is with a session-level lock, but such locks are only released manually
    # or by closing the connection. There's no easy way to do the latter with Ecto due to how the
    # connection pool works, and with the former it's hard to guarantee the separate unlock query
    # will run if e.g. the process dies. So the approach taken here is to spawn a helper process
    # that opens a transaction, acquires a transaction-level lock, and holds onto it until told
    # to release it. As demonstrated in the tests for this module, this results in the lock being
    # properly released even if the calling process dies while holding it.

    parent = self()

    locker =
      spawn_link(fn ->
        Process.flag(:trap_exit, true)

        Repo.transaction(
          fn ->
            case Repo.query!("SELECT pg_try_advisory_xact_lock($1)", [key]) do
              %{rows: [[true]]} ->
                send(parent, :acquired)

                receive do
                  :release -> nil
                  {:EXIT, _, _} -> nil
                end

              %{rows: [[false]]} ->
                send(parent, :not_acquired)
            end
          end,
          timeout: :infinity
        )
      end)

    result =
      receive do
        :acquired ->
          try do
            func.(:ok)
          after
            send(locker, :release)
          end

        :not_acquired ->
          func.(:error)
      end

    # Wait for the spawned process to release the lock before returning, ensuring if `acquire`
    # is called sequentially by the same process, an attempt will not fail due to the lock still
    # being "held" by the previous call

    monitor = Process.monitor(locker)

    receive do
      {:DOWN, ^monitor, _, _, _} -> nil
    end

    result
  end
end
