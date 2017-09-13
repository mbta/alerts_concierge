defmodule AlertProcessor.Subscription.Snapshot do
  @moduledoc """
  Manages snapshots of a subscripton and its informed_entities
  at a specific point in time
  """
  alias AlertProcessor.{Model, Repo, StructHelper}
  alias Model.{InformedEntity, Subscription, User}
  alias Calendar.Time.Parse, as: TParse
  alias Calendar.DateTime.Parse, as: DTParse
  import Ecto.Query

  def get_snapshots_by_datetime(user, datetime) do
    query = from s in Subscription,
    where: s.user_id == ^user.id

    with {:ok, user_version} <- get_user_version(user, datetime) do
      result =
        query
        |> Repo.all
        |> Enum.map(&(build_snapshot_for_datetime(&1, user_version, datetime)))
      {:ok, result}
    else
      _ -> :error
    end
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
    user_params = snapshot.user
      |> set_dnd_times()
      |> set_vacation()
    user = StructHelper.to_struct(User, user_params)
    informed_entities = Enum.map(snapshot.informed_entities, fn(ie) ->
      StructHelper.to_struct(InformedEntity, ie)
    end)

    Subscription
    |> StructHelper.to_struct(snapshot.subscription)
    |> set_times()
    |> set_types()
    |> set_relevant_days()
    |> Map.merge(%{
      user: user,
      informed_entities: informed_entities,
      alert_priority_type: String.to_existing_atom(snapshot.subscription["alert_priority_type"])
    })
  end

  defp set_dnd_times(%{
    "do_not_disturb_start" => dnd_start,
    "do_not_disturb_end" => dnd_end
  } = user_params) do
    params = if is_nil(dnd_start) do
      user_params
    else
      Map.put(user_params, "do_not_disturb_start", TParse.iso8601!(dnd_start))
    end

    if is_nil(dnd_end) do
      params
    else
      Map.put(params, "do_not_disturb_end", TParse.iso8601!(dnd_end))
    end
  end

  defp set_vacation(%{
    "vacation_start" => v_start,
    "vacation_end" => v_end
  } = user_params) do
    params = if is_nil(v_start) do
      user_params
    else
      {:ok, dt} = DTParse.rfc3339_utc(v_start)
      Map.put(user_params, "vacation_start", dt)
    end

    if is_nil(v_end) do
      params
    else
      {:ok, dt} = DTParse.rfc3339_utc(v_end)
      Map.put(params, "vacation_end", dt)
    end
  end

  defp set_relevant_days(sub) do
    days = Enum.map(sub.relevant_days, fn(rd) ->
      String.to_existing_atom(rd)
    end)
    Map.put(sub, :relevant_days, days)
  end
  defp set_types(sub), do: Map.put(sub, :type, String.to_existing_atom(Map.get(sub, :type)))
  defp set_times(sub) do
    start_time = Time.from_iso8601!(Map.get(sub, :start_time))
    end_time = Time.from_iso8601!(Map.get(sub, :end_time))

    sub
    |> Map.put(:start_time, start_time)
    |> Map.put(:end_time, end_time)
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
end
