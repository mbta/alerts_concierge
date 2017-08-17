defmodule AlertProcessor.Subscription.Snapshot do
  @moduledoc """
  Manages snapshots of a subscripton and its informed_entities
  at a specific point in time
  """
  alias AlertProcessor.{Model.Subscription, Repo}
  import Ecto.Query

  def get_snapshots_by_datetime(user, datetime) do
    query = from s in Subscription,
      where: s.user_id == ^user.id

    query
    |> Repo.all
    |> Enum.map(&(build_snapshot_for_datetime(&1, datetime)))
  end

  defp build_snapshot_for_datetime(sub, datetime) do
    sub
    |> PaperTrail.get_versions()
    |> Enum.reject(fn(version) ->
      NaiveDateTime.compare(version.inserted_at, datetime) == :gt
    end)
    |> Enum.reduce(%{}, fn(%{item_changes: changes}, snapshot) ->
       Map.merge(snapshot, changes)
    end)
  end
end
