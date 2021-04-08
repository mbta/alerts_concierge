defmodule AlertProcessor.Lock do
  @moduledoc "Provides a database-backed exclusive lock."
  alias AlertProcessor.Repo

  # Arbitrary integer; should be unique among all locks used with this database
  @key 0

  @doc """
  Tries to acquire an exclusive advisory lock using the `AlertProcessor.Repo` database. The given
  function will be called with `:ok` if the lock was acquired, or `:error` if the lock is already
  in use (i.e. a function that was called with `:ok` is currently executing elsewhere).

  Returns whatever the passed function returns.

  Note: The function is not executed in a transaction, allowing multiple transactions to be
  performed "within" a lock. The lack of a `Repo.checkout` in Ecto 2 prevents us from using a
  session-level lock to do this, so instead we spawn a process that acquires a transaction-level
  lock and holds the transaction open until the passed function is done executing.
  """
  @spec acquire((:ok | :error -> any)) :: any
  def acquire(func) do
    parent = self()

    locker =
      spawn_link(fn ->
        Process.flag(:trap_exit, true)

        Repo.transaction(
          fn ->
            case Repo.query!("SELECT pg_try_advisory_xact_lock($1)", [@key]) do
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
