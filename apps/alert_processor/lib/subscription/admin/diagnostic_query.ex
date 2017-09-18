defmodule AlertProcessor.Subscription.DiagnosticQuery do
  alias AlertProcessor.{Model, Repo}
  alias Model.{SavedAlert, Notification}
  import Ecto.Query

  def get_notifications(user_id, alert_id) do
    notification_query = from n in Notification,
      where: n.user_id == ^user_id,
      where: n.alert_id == ^alert_id,
      select: n

    Repo.all(notification_query)
  end

  def get_alert(alert_id) do
    case Repo.get_by(SavedAlert, alert_id: alert_id) do
      %SavedAlert{} = alert -> {:ok, alert}
      _ -> {:error, :no_alert}
    end
  end

  def get_alert_versions(alert, datetime) do
    result =
      alert
      |> PaperTrail.get_versions()
      |> Enum.reject(fn(version) ->
        version_time = DateTime.from_naive!(version.inserted_at, "Etc/UTC")
        DateTime.compare(version_time, datetime) == :gt
      end)

    if result == [] do
      {:error, :no_versions}
    else
      {:ok, result}
    end
  end

  def get_user_version(user, datetime) do
    result =
      user
      |> PaperTrail.get_versions()
      |> Enum.reject(fn(version) ->
        version_time = DateTime.from_naive!(version.inserted_at, "Etc/UTC")
        DateTime.compare(version_time, datetime) == :gt
      end)
      |> Enum.reduce(%{}, fn(%{item_changes: changes}, acc) ->
        Map.merge(acc, changes)
      end)

    if result == %{} do
      :error
    else
      {:ok, result}
    end
  end

  def get_informed_entities(nil), do: []
  def get_informed_entities(ids) do
    query = from v in PaperTrail.Version,
      where: v.id in ^ids

    query
    |> Repo.all()
    |> Enum.map(&(&1.item_changes))
  end
end
