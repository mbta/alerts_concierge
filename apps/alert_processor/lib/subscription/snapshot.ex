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
      version_time = DateTime.from_naive!(version.inserted_at, "Etc/UTC")
      DateTime.compare(version_time, datetime) == :gt
    end)
    |> Enum.reduce(%{subscription: %{}, informed_entities: []},
        fn(%{item_changes: changes, meta: meta},
          %{subscription: sub}) ->
          %{
            subscription: Map.merge(sub, changes),
            informed_entities: get_informed_entities(meta["informed_entity_version_ids"])
          }
        end)
  end

  defp get_informed_entities(nil), do: []
  defp get_informed_entities(ids) do
    query = from v in PaperTrail.Version,
      where: v.id in ^ids

    query
    |> Repo.all()
    |> Enum.map(&(&1.item_changes))
  end
end
