defmodule AlertProcessor.Model.Metadata do
  @moduledoc """
  Generic schema that allows using the database as a key-value store.

  Note: Does not provide conveniences for handling concurrent access, as the only use of this
  schema currently is within a database-level exclusive lock (see `AlertProcessor.Lock`).
  """

  @type key :: atom
  @type value :: map

  use Ecto.Schema
  import Ecto.Query
  alias AlertProcessor.Repo

  @primary_key {:id, AlertProcessor.AtomType, autogenerate: false}

  schema "metadata" do
    field(:data, :map, default: %{})
    timestamps(type: :utc_datetime)
  end

  @spec get(key) :: value
  def get(id) when is_atom(id) do
    case Repo.get(__MODULE__, id) do
      nil -> %{}
      %{data: data} -> data
    end
  end

  @spec put(key, value) :: :ok
  def put(id, data) when is_atom(id) and is_map(data) do
    Repo.insert!(%__MODULE__{id: id, data: data},
      on_conflict: [set: [data: data, updated_at: DateTime.utc_now()]],
      conflict_target: :id
    )

    :ok
  end

  @spec delete(key) :: :ok
  def delete(id) when is_atom(id) do
    Repo.delete_all(from(m in __MODULE__, where: m.id == ^id))
    :ok
  end
end
