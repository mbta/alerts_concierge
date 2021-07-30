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

  Note: The function is not executed in a transaction, allowing multiple transactions to be
  performed "within" a lock. The lack of a `Repo.checkout` in Ecto 2 prevents us from using a
  session-level lock to do this, so instead we spawn a process that acquires a transaction-level
  lock and holds the transaction open until the passed function is done executing.
  """
  @spec acquire(atom | non_neg_integer, (:ok | :error -> any)) :: any

  def acquire(key, func) when is_atom(key) do
    @keys |> Map.fetch!(key) |> acquire(func)
  end

  def acquire(key, func) when is_integer(key) and key >= 0 do
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
