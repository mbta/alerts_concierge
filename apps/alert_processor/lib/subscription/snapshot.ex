defmodule AlertProcessor.Subscription.Snapshot do
  @moduledoc """
  Manages snapshots of a subscripton and its informed_entities
  at a specific point in time
  """
  alias AlertProcessor.Model.Subscription

  def get_snapshots_by_date(user, date) do
    Subscription.for_user(user)
    |> Enum.map(&(build_snapshot_for_date(&1, date)))
  end

  defp build_snapshot_for_date(sub, date) do
    sub
    |> PaperTrail.get_versions()
    |> Enum.filter(fn(version) ->
      Date.compare(version.inserted_at, date) != :gt
    end)
    |> Enum.reduce(%{}, fn(%{item_changes: changes}, snapshot) ->
       Map.merge(snapshot, changes)
    end)
  end
end
