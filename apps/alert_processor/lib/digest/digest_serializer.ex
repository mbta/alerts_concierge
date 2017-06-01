defmodule AlertProcessor.DigestSerializer do
  @moduledoc """
  Converts alerts into digest email text
  """
  alias AlertProcessor.{Helpers.DateTimeHelper, Model}
  alias Model.{Alert, Digest}
  @date_groups [:upcoming_weekend, :upcoming_week, :next_weekend, :future]

  @doc """
  Takes a Digest and serializes each alert into
  the format it will be presented in an email
  """
  @spec serialize(Digest.t)
  :: [%{name: atom, title: String.t, alerts: [Alert.t]}]
  def serialize(digest) do
    digest.digest_date_group
    |> Map.from_struct()
    |> Enum.reduce([], fn({name, value}, acc) ->
      filtered_alerts = filter_alerts(digest.alerts, value.alert_ids)
      title = title(name, value.timeframe)
      if Enum.empty?(filtered_alerts) do
        acc
      else
        acc ++ [%{name: name, title: title, alerts: filtered_alerts}]
      end
    end)
    |> Enum.sort_by(fn(%{name: name}) ->
      Enum.find_index(@date_groups, &(&1 == name))
    end)
  end

  defp filter_alerts(alerts, alert_ids) do
    Enum.filter(alerts, &(Enum.member?(alert_ids, &1.id)))
  end

  defp title(date_group, {start_date, end_date}) do
    prefix = prefix(date_group)
    cond do
      date_group == :future ->
        prefix
      start_date.month == end_date.month ->
        "#{prefix}, #{DateTimeHelper.month_name(start_date)} #{start_date.day} - #{end_date.day}"
      true ->
        "#{prefix}, #{DateTimeHelper.month_name(start_date)} #{start_date.day} - #{DateTimeHelper.month_name(end_date)} #{end_date.day}"
    end
  end

  defp prefix(date_group) do
    case date_group do
      :upcoming_weekend -> "This Weekend"
      :upcoming_week -> "Next Week"
      :next_weekend -> "Next Weekend"
      :future -> "Future Alerts"
    end
  end
end
