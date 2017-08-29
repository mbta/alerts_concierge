defmodule AlertProcessor.Subscription.Snapshot do
  @moduledoc """
  Manages snapshots of a subscripton and its informed_entities
  at a specific point in time
  """
  alias AlertProcessor.{Model, Repo}
  alias Model.{InformedEntity, Subscription, User}
  import Ecto.Query

  def get_snapshots_by_datetime(user, datetime) do
    user_version = get_user_version(user, datetime)

    query = from s in Subscription,
      where: s.user_id == ^user.id

    query
    |> Repo.all
    |> Enum.map(&(build_snapshot_for_datetime(&1, user_version, datetime)))
  end

  defp build_snapshot_for_datetime(sub, user_version, datetime) do
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
    |> Map.merge(%{user: user_version})
    |> serialize()
  end

  defp serialize(snapshot) do
    user = to_struct(User, snapshot.user)
    informed_entities = Enum.map(snapshot.informed_entities, fn(ie) ->
      to_struct(InformedEntity, ie)
    end)
    subscription =
      Subscription
      |> to_struct(snapshot.subscription)
      |> Map.merge(%{
        user: user,
        informed_entities: informed_entities
      })
  end

  def to_struct(kind, attrs) do
    struct = struct(kind)
    Enum.reduce Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end
  end

  defp get_informed_entities(nil), do: []
  defp get_informed_entities(ids) do
    query = from v in PaperTrail.Version,
      where: v.id in ^ids

    query
    |> Repo.all()
    |> Enum.map(&(&1.item_changes))
  end

  defp get_user_version(user, datetime) do
    user
    |> PaperTrail.get_versions()
    |> Enum.reject(fn(version) ->
      version_time = DateTime.from_naive!(version.inserted_at, "Etc/UTC")
      DateTime.compare(version_time, datetime) == :gt
    end)
    |> Enum.reduce(%{}, fn(%{item_changes: changes}, acc) ->
      Map.merge(acc, changes)
    end)
  end
end
