defmodule AlertProcessor.Subscription.Snapshot do
  @moduledoc """
  Manages snapshots of a subscripton and its informed_entities
  at a specific point in time
  """
  alias AlertProcessor.{AlertParser, Helpers.StringHelper, Model,
    Repo, Helpers.StructHelper, Subscription.DiagnosticQuery}
  alias Model.{Alert, InformedEntity, Subscription, User}
  alias Calendar.Time.Parse, as: TParse
  alias Calendar.DateTime.Parse, as: DTParse
  import Ecto.Query

  def get_snapshots_by_datetime(user, datetime) do
    query = from s in Subscription,
    where: s.user_id == ^user.id

    with {:ok, user_version} <- DiagnosticQuery.get_user_version(user, datetime) do
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
            informed_entities: DiagnosticQuery.get_informed_entities(meta["informed_entity_version_ids"])
          }
        end)
    |> Map.merge(%{user: user_version})
    |> serialize()
  end

  def serialize_alert_versions(alert_versions) do
    snapshot =
      alert_versions
      |> Enum.reduce(%{}, fn(%{item_changes: changes}, acc) ->
        Map.merge(acc, changes["data"])
      end)
      |> serialize_alert()
      |> serialize_active_periods()
      |> serialize_informed_entities()

    {:ok, StructHelper.to_struct(Alert, snapshot)}
  end

  defp serialize_alert(alert) do
    Map.merge(alert, %{
      "effect_name" => StringHelper.split_capitalize(alert["effect_detail"], "_"),
      "header" => AlertParser.parse_translation(alert["header_text"]),
      "severity" => AlertParser.parse_severity(alert["severity"]),
      "last_push_notification" => DateTime.from_unix!(alert["last_push_notification_timestamp"]),
      "service_effect" => AlertParser.parse_translation(alert["service_effect_text"]),
      "description" => AlertParser.parse_translation(alert["description_text"]),
      "timeframe" => AlertParser.parse_translation(alert["timeframe_text"]),
      "recurrence" => AlertParser.parse_translation(alert["recurrence_text"])
    })
  end

  defp serialize_active_periods(alert) do
    active_periods = Enum.map(alert["active_period"], fn(ap) ->
      serialize_active_period(ap)
    end)
    Map.put(alert, "active_period", active_periods)
  end

  def serialize_active_period(map) do
    for {key, val} <- map, into: %{} do
       {String.to_existing_atom(key), DateTime.from_unix!(val)}
    end
  end

  defp serialize_informed_entities(alert) do
    informed_entities = Enum.map(alert["informed_entity"], fn(ie) ->
      StructHelper.to_struct(InformedEntity, ie)
    end)
    Map.put(alert, "informed_entities", informed_entities)
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
end
