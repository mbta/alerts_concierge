defmodule AlertProcessor.Memory do
  defstruct [
    :atom,
    :atom_used,
    :binary,
    :code,
    :ets,
    :processes,
    :processes_used,
    :system,
    :total
  ]

  @type t :: %__MODULE__{
          atom: integer(),
          atom_used: integer(),
          binary: integer(),
          code: integer(),
          ets: integer(),
          processes: integer(),
          processes_used: integer(),
          system: integer(),
          total: integer()
        }

  @doc """
  Returns a list with information about memory dynamically allocated by the Erlang emulator. The keys are atoms describing memory type. The values are the memory sizes in bytes. See the :erlang.memory() documentation for details.

      iex> memory = AlertProcessor.Memory.now()
      iex> is_map(memory)
      true
      iex> memory |> Map.keys() |> Enum.all?(&(Map.has_key?(%AlertProcessor.Memory{}, &1)))
      true
  """
  @spec now() :: t
  def now(), do: :erlang.memory() |> Map.new()

  @doc """
  Calculate the difference between two memory usage structs on a type-by-type basis

  iex> a = %{atom: 10, atom_used: 9, binary: 8, code: 7, ets: 6, processes: 5, processes_used: 4, system: 3, total: 2}
  iex> b = %{atom: 3, atom_used: 4, binary: 5, code: 6, ets: 7, processes: 8, processes_used: 9, system: 10, total: 11}
  iex> AlertProcessor.Memory.diff(b, a)
  %{atom: -7, atom_used: -5, binary: -3, code: -1, ets: 1, processes: 3, processes_used: 5, system: 7, total: 9}
  """
  @spec diff(t, t) :: t
  def diff(b, a), do: Map.new(b, fn {key, value} -> {key, value - a[key]} end)

  @doc """
  Convert a memory struct to a loggable string.

  iex> mem = %{atom: 3, atom_used: 4, binary: 5, code: 6, ets: 7, processes: 8, processes_used: 9, system: 10, total: 11}
  iex> AlertProcessor.Memory.to_string(mem)
  "atom=3 atom_used=4 binary=5 code=6 ets=7 processes=8 processes_used=9 system=10 total=11"
  """
  @spec to_string(t) :: String.t()
  def to_string(mem) do
    mem
    |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
    |> Enum.join(" ")
  end
end
