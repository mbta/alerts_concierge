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
  Executes the given query. It is run inside a transaction that is then rolled back, using a
  temporary role that only has SELECT permission, and only for columns that don't contain
  personally identifying or sensitive information. Only one statement is allowed (thanks to
  `Repo.query/1` using prepared statements), preventing the query from easily "escaping" the
  restrictions, since `COMMIT`, `SET ROLE`, etc. will use up the single allowed statement.

  These restrictions are intended primarily to avoid accidental data modification or exposure by
  trusted administrators. They are *not* a guarantee that a sufficiently motivated hostile actor,
  if allowed to pass arbitrary SQL to this function, could not somehow exploit it.
  """
  def execute(%__MODULE__{query: query}) do
    {:error, result} = Repo.transaction(fn -> query |> do_execute() |> Repo.rollback() end)
    result
  end

  @permitted_columns [
    {"alerts", :all},
    {"informed_entities", :all},
    {"metadata", :all},
    {"notification_subscriptions", :all},
    {"notifications", ~w(
      id
      user_id
      alert_id
      header
      send_after
      status
      inserted_at
      updated_at
      last_push_notification
      service_effect
      description
      url
      closed_timestamp
      type
    )},
    {"password_resets", :all},
    {"saved_queries", :all},
    {"trips", :all},
    {"users", ~w(
      id
      inserted_at
      updated_at
      role
      digest_opt_in
      sms_opted_out_at
      communication_mode
      email_rejection_status
    )},
    {"versions", ~w(id event item_type item_id originator_id origin meta inserted_at)}
  ]

  defp do_execute(query) do
    role = "temp_restricted_#{Ecto.UUID.generate() |> String.replace("-", "_")}"
    Repo.query!("CREATE ROLE #{role}")

    Enum.each(@permitted_columns, fn
      {table, :all} ->
        Repo.query!("GRANT SELECT ON #{table} TO #{role}")

      {table, columns} when is_list(columns) ->
        columns_for_grant = columns |> Enum.map(&~s("#{&1}")) |> Enum.join(",")
        Repo.query!("GRANT SELECT (#{columns_for_grant}) ON #{table} TO #{role}")
    end)

    Repo.query!("SET LOCAL ROLE #{role}")
    result = Repo.query(query)

    # In case someone was trying to be clever and the query was a `COMMIT`, the role now exists
    # for real, so we need to drop it
    Repo.query!("DROP OWNED BY #{role}")
    Repo.query!("DROP ROLE #{role}")

    result
  end
end
