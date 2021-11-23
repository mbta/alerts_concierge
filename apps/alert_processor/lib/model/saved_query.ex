defmodule AlertProcessor.Model.SavedQuery do
  @moduledoc "A saved query on the admin database console."

  @type id :: String.t()
  @type t :: %__MODULE__{
          id: id,
          label: String.t(),
          query: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  use Ecto.Schema
  alias Ecto.Changeset
  alias AlertProcessor.Repo
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "saved_queries" do
    field(:label, :string, null: false)
    field(:query, :string, null: false)

    timestamps()
  end

  def all, do: Repo.all(from(q in __MODULE__, order_by: :label))

  @doc "Builds a changeset for inserts or updates."
  def changeset(struct, params \\ %{}) do
    struct
    |> Changeset.cast(params, [:label, :query])
    |> Changeset.validate_required([:label, :query])
  end

  @doc """
  Executes the given query inside a transaction which is then rolled back, providing a basic
  safeguard against changing any data.
  """
  def execute(%__MODULE__{query: query}) do
    {:error, result} = Repo.transaction(fn -> query |> Repo.query() |> Repo.rollback() end)
    result
  end
end
