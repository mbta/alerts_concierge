defmodule AlertProcessor.Model.SavedAlert do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias AlertProcessor.Repo

  @type t :: %__MODULE__{
    id: String.t,
    last_modified: DateTime.t,
    data: Alert.t
  }

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "alerts" do
    field :alert_id, :string
    field :last_modified, :utc_datetime
    field :data, :map

    timestamps()
  end

  @create_fields ~w(alert_id data last_modified)a
  @update_fields ~w(data last_modified)a

  @doc """
  Changeset for persisting a Subscription
  """
  @spec create_changeset(__MODULE__.t, map) :: Ecto.Changeset.t
  def create_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @create_fields)
    |> validate_required(@create_fields)
    |> unique_constraint(:alert_id)
  end

  @doc """
  Changeset for updating a Subscription
  """
  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @update_fields)
  end

  def save_new_alert(struct, params) do
    struct
    |> create_changeset(params)
    |> PaperTrail.insert!()
  end

  def update_existing_alert(struct, params) do
    struct
    |> update_changeset(params)
    |> PaperTrail.insert!()
  end

  def save!(alerts) do
    alert_ids = Enum.map(alerts, &(&1["id"]))
    query = from a in __MODULE__,
      where: a.alert_id in ^alert_ids

    existing_alerts = Repo.all(query)
    alert_pairs = pair_alerts(alerts, existing_alerts)

    for {alert, existing} <- alert_pairs do
      params = %{
        alert_id: alert["id"],
        last_modified: DateTime.from_unix!(alert["last_modified_timestamp"]),
        data: alert
      }

      if existing == nil do
        save_new_alert(%__MODULE__{}, params)
      else
        update_if_changed(existing, params)
      end
    end
  end

  defp pair_alerts(alerts, existing_alerts) do
    for alert <- alerts do
      existing_alert = Enum.find(existing_alerts, &(alert["id"] == &1.alert_id))
      {alert, existing_alert}
    end
  end

  defp update_if_changed(%__MODULE__{last_modified: last_modified} = existing, params) do
    unless DateTime.compare(last_modified, params.last_modified) == :eq do
      update_existing_alert(existing, params)
    end
  end
end
