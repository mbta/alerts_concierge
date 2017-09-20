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
        |> Enum.reject(&(&1 == :error))
      {:ok, result}
    else
      _ -> :error
    end
  end

  defp build_snapshot_for_datetime(sub, user_version, datetime) do
    with {:ok, versions} <- get_relevant_versions(sub, datetime),
      {:ok, snapshot_data} <- get_snapshot_data(versions),
      data_with_user <- Map.merge(snapshot_data, %{user: user_version}) do
        serialize(data_with_user)
    else
      _ -> :error
    end
  end

  defp get_relevant_versions(sub, datetime) do
    versions = sub
    |> PaperTrail.get_versions()
    |> Enum.reject(fn(version) ->
      version_time = DateTime.from_naive!(version.inserted_at, "Etc/UTC")
      DateTime.compare(version_time, datetime) == :gt
    end)

    if versions == [] do
      :error
    else
      {:ok, versions}
    end
  end

  defp get_snapshot_data(versions) do
    result = Enum.reduce(versions, %{subscription: %{}, informed_entities: []},
      fn(%{event: event, item_changes: changes, meta: meta},
        %{subscription: sub}) ->
        if event == "delete" do
          %{subscription: %{}, informed_entities: []}
        else
          ies = DiagnosticQuery.get_informed_entities(meta["informed_entity_version_ids"])
          %{
            subscription: Map.merge(sub, changes),
            informed_entities: serialize_informed_entities(ies)
          }
        end
      end)

    if result == %{subscription: %{}, informed_entities: []} do
      :error
    else
      {:ok, result}
    end
  end

  def serialize_alert_versions(alert_versions) do
    snapshot =
      alert_versions
      |> Enum.reduce(%{}, fn(%{item_changes: changes}, acc) ->
        Map.merge(acc, changes["data"])
      end)
      |> serialize_alert()
      |> serialize_active_periods()

    snapshot = Map.put(snapshot, "informed_entities", serialize_informed_entities(snapshot["informed_entity"]))

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

  defp serialize_informed_entities(nil), do: []
  defp serialize_informed_entities(informed_entities) do
   Enum.map(informed_entities, fn(ie) ->
      InformedEntity
      |> StructHelper.to_struct(ie)
      |> set_facility_type()
    end)
  end

  defp set_facility_type(%{facility_type: nil} = ie), do: ie
  defp set_facility_type(%{facility_type: ft} = ie) do
    Map.put(ie, :facility_type, String.to_existing_atom(ft))
  end
  defp set_facility_type(ie), do: ie

  defp serialize(snapshot) do
    user_params = snapshot.user
      |> set_dnd_times()
      |> set_vacation()
    user = StructHelper.to_struct(User, user_params)

    Subscription
    |> StructHelper.to_struct(snapshot.subscription)
    |> set_times()
    |> set_types()
    |> set_relevant_days()
    |> Map.merge(%{
      user: user,
      informed_entities: snapshot.informed_entities,
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

  defp set_times(%{start_time: start_time, end_time: end_time} = sub) do
    sub = if is_nil(start_time) do
      sub
    else
      Map.put(sub, :start_time, Time.from_iso8601!(start_time))
    end

    if is_nil(end_time) do
      sub
    else
      Map.put(sub, :end_time, Time.from_iso8601!(end_time))
    end
  end
end
