defmodule AlertProcessor.DigestSerializer do
  @moduledoc """
  Converts alerts into digest email text
  """
  alias AlertProcessor.{Helpers.DateTimeHelper, Model}
  alias Model.{Alert, Digest}
  alias Calendar.DateTime, as: DT
  @date_groups [:upcoming_weekend, :upcoming_week, :next_weekend, :future]

  @doc """
  Takes a Digest and serializes each alert into
  the format it will be presented in an email
  """
  @spec serialize(Digest.t)
  :: [%{name: atom, title: String.t, alerts: [Alert.t]}]
  def serialize(digest) do
    ddg = digest.digest_date_group
    Enum.flat_map(@date_groups, fn date_group ->
      section = Map.get(ddg, date_group)
      case filter_alerts(digest.alerts, section.alert_ids) do
        [] -> []
        alerts ->
          title = title(date_group, section.timeframe)
          [%{title: title, alerts: alerts}]
      end
    end)
  end

  defp filter_alerts(alerts, alert_ids) do
    Enum.filter(alerts, &(Enum.member?(alert_ids, &1.id)))
  end

  defp title(date_group, {start_date, end_date}) do
    adjusted_end_date = DT.subtract!(end_date, 86_400)
    prefix = prefix(date_group)
    cond do
      date_group == :future ->
        prefix
      start_date.month == adjusted_end_date.month ->
        "#{prefix}, #{DateTimeHelper.month_name(start_date)} #{start_date.day} - #{adjusted_end_date.day}"
      true ->
        "#{prefix}, #{DateTimeHelper.month_name(start_date)} #{start_date.day} - #{DateTimeHelper.month_name(adjusted_end_date)} #{adjusted_end_date.day}"
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
